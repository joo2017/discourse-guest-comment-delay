# frozen_string_literal: true

require "erb"
require "time"

require_relative "discourse_guest_comment_delay/effective_delay_resolver"
require_relative "discourse_guest_comment_delay/guest_topic_state"
require_relative "discourse_guest_comment_delay/posts_controller_extension"
require_relative "discourse_guest_comment_delay/post_serializer_extension"
require_relative "discourse_guest_comment_delay/request_scope_extension"
require_relative "discourse_guest_comment_delay/topic_notice"
require_relative "discourse_guest_comment_delay/topic_view_filter"
require_relative "discourse_guest_comment_delay/topic_view_hook"
require_relative "discourse_guest_comment_delay/topic_view_extension"

module DiscourseGuestCommentDelay
  PLUGIN_NAME = "discourse-guest-comment-delay"
  CATEGORY_CUSTOM_FIELD = "guest_comment_delay_minutes_override"

  module_function

  def register!(plugin_instance)
    register_category_field!(plugin_instance)
    register_render_path_redaction!
    register_post_placeholder_serializer!(plugin_instance)
  end

  def register_category_field!(plugin_instance)
    if plugin_instance.respond_to?(:register_category_custom_field_type)
      plugin_instance.register_category_custom_field_type(CATEGORY_CUSTOM_FIELD, :integer)
    elsif defined?(Category)
      Category.register_custom_field_type(CATEGORY_CUSTOM_FIELD, :integer)
    end

    if plugin_instance.respond_to?(:register_preloaded_category_custom_fields)
      plugin_instance.register_preloaded_category_custom_fields(CATEGORY_CUSTOM_FIELD)
    elsif defined?(Site) && Site.respond_to?(:preloaded_category_custom_fields)
      Site.preloaded_category_custom_fields << CATEGORY_CUSTOM_FIELD unless Site.preloaded_category_custom_fields.include?(CATEGORY_CUSTOM_FIELD)
    end
  end

  def register_render_path_redaction!
    prepend_once(ApplicationController, DiscourseGuestCommentDelay::RequestScopeExtension) if defined?(ApplicationController)
    prepend_once(PostsController, DiscourseGuestCommentDelay::PostsControllerExtension) if defined?(PostsController)
    prepend_once(TopicView, DiscourseGuestCommentDelay::TopicViewExtension) if defined?(TopicView)
  end

  def register_post_placeholder_serializer!(plugin_instance)
    prepend_once(BasicPostSerializer, DiscourseGuestCommentDelay::PostSerializerExtension::Basic) if defined?(BasicPostSerializer)
    prepend_once(PostSerializer, DiscourseGuestCommentDelay::PostSerializerExtension::Post) if defined?(PostSerializer)

    return unless plugin_instance.respond_to?(:add_to_serializer)

    plugin_instance.add_to_serializer(
      :post,
      :guest_hidden_placeholder,
      include_condition: -> { DiscourseGuestCommentDelay.guest_hidden_post?(post: object, scope: scope) }
    ) do
      true
    end

    plugin_instance.add_to_serializer(
      :post,
      :guest_hidden_delay_minutes,
      include_condition: -> { DiscourseGuestCommentDelay.guest_hidden_post?(post: object, scope: scope) }
    ) do
      DiscourseGuestCommentDelay.delay_minutes_for_post(post: object)
    end
  end

  def guest_hidden_post?(post:, scope: nil)
    return false unless guest_scope?(scope)
    return false unless post.respond_to?(:post_number) && post.post_number.to_i > 1

    !EffectiveDelayResolver.new.visible_to_guest?(post: post, category: post.topic&.category)
  end

  def guest_hidden_post_for_user?(post:, user: nil)
    guest_hidden_post?(post: post, scope: user)
  end

  def with_request_scope(user)
    previous_user = Thread.current[:guest_comment_delay_request_user]
    previous_active = Thread.current[:guest_comment_delay_request_active]
    Thread.current[:guest_comment_delay_request_user] = user
    Thread.current[:guest_comment_delay_request_active] = true
    yield
  ensure
    Thread.current[:guest_comment_delay_request_user] = previous_user
    Thread.current[:guest_comment_delay_request_active] = previous_active
  end

  def request_scope_user
    Thread.current[:guest_comment_delay_request_user]
  end

  def request_scope_active?
    Thread.current[:guest_comment_delay_request_active] == true
  end

  def decorate_hidden_post_for_guest(post, user: nil)
    return post unless guest_hidden_post_for_user?(post: post, user: user)
    return post if post.instance_variable_get(:@guest_comment_delay_redacted)

    placeholder_html_value = placeholder_html(delay_minutes: delay_minutes_for_post(post: post))
    placeholder_text_value = placeholder_text(delay_minutes: delay_minutes_for_post(post: post))

    post.define_singleton_method(:cooked) { placeholder_html_value }
    post.define_singleton_method(:raw) { placeholder_text_value }
    post.define_singleton_method(:excerpt) { |*| placeholder_text_value }
    post.instance_variable_set(:@guest_comment_delay_redacted, true)
    post
  end

  def decorate_hidden_posts_for_guest(posts, user: nil)
    Array(posts).map { |post| decorate_hidden_post_for_guest(post, user: user) }
  end

  def reduce_cooked_fragment_for_guest!(fragment:, post:)
    return fragment unless request_scope_active?
    return fragment unless request_scope_user.nil?
    return fragment unless post
    return fragment unless guest_hidden_post_for_user?(post: post, user: nil)

    fragment.children.remove
    fragment.add_child(placeholder_html(delay_minutes: delay_minutes_for_post(post: post)))
    fragment
  end

  def delay_minutes_for_post(post:)
    EffectiveDelayResolver.new.effective_delay_minutes(category: post.topic&.category)
  end

  def placeholder_duration_text(delay_minutes:)
    return "几分钟" unless delay_minutes.to_i.positive?

    delay_minutes % 60 == 0 ? "#{delay_minutes / 60}小时" : "#{delay_minutes}分钟"
  end

  def placeholder_text(delay_minutes:)
    template = if defined?(SiteSetting) && SiteSetting.respond_to?(:guest_comment_delay_placeholder_text)
      SiteSetting.guest_comment_delay_placeholder_text
    else
      "非会员无法阅读发表后%{delay_duration}内的评论。登录后可立即查看^^"
    end

    format(
      template,
      delay_duration: placeholder_duration_text(delay_minutes: delay_minutes),
      delay_minutes: delay_minutes.to_i
    )
  end

  def placeholder_html(delay_minutes:)
    <<~HTML.strip
      <div class="guest-comment-delay-placeholder">#{ERB::Util.html_escape(placeholder_text(delay_minutes: delay_minutes))}</div>
    HTML
  end

  def guest_scope?(scope)
    return true if scope.nil?
    return scope.anonymous? if scope.respond_to?(:anonymous?)
    return scope.user.nil? if scope.respond_to?(:user)

    false
  end

  def prepend_once(klass, mod)
    return unless defined?(klass)
    return if klass.ancestors.include?(mod)

    klass.prepend(mod)
  end
end
