# frozen_string_literal: true

RSpec.describe DiscourseGuestCommentDelay do
  let(:plugin_instance) do
    instance_double(
      "PluginInstance",
      register_category_custom_field_type: nil,
      register_preloaded_category_custom_fields: nil,
      add_to_serializer: nil
    )
  end

  around do |example|
    original_category = Object.const_defined?(:Category) ? Category : nil
    original_application_controller = Object.const_defined?(:ApplicationController) ? ApplicationController : nil
    original_posts_controller = Object.const_defined?(:PostsController) ? PostsController : nil
    original_post_item_excerpt = Object.const_defined?(:PostItemExcerpt) ? PostItemExcerpt : nil
    original_basic_post_serializer = Object.const_defined?(:BasicPostSerializer) ? BasicPostSerializer : nil
    original_post_serializer = Object.const_defined?(:PostSerializer) ? PostSerializer : nil
    original_search_post_serializer = Object.const_defined?(:SearchPostSerializer) ? SearchPostSerializer : nil
    original_topic_view = Object.const_defined?(:TopicView) ? TopicView : nil

    Object.send(:remove_const, :Category) if Object.const_defined?(:Category)
    Object.send(:remove_const, :ApplicationController) if Object.const_defined?(:ApplicationController)
    Object.send(:remove_const, :PostsController) if Object.const_defined?(:PostsController)
    Object.send(:remove_const, :PostItemExcerpt) if Object.const_defined?(:PostItemExcerpt)
    Object.send(:remove_const, :BasicPostSerializer) if Object.const_defined?(:BasicPostSerializer)
    Object.send(:remove_const, :PostSerializer) if Object.const_defined?(:PostSerializer)
    Object.send(:remove_const, :SearchPostSerializer) if Object.const_defined?(:SearchPostSerializer)
    Object.send(:remove_const, :TopicView) if Object.const_defined?(:TopicView)

    category_class = Class.new do
      class << self
        attr_reader :registered_fields

        def register_custom_field_type(name, type)
          @registered_fields ||= []
          @registered_fields << [name, type]
        end
      end
    end

    application_controller_class = Class.new do
      class << self
        attr_reader :prepended_modules

        def prepend(mod)
          @prepended_modules ||= []
          @prepended_modules << mod
          super
        end
      end
    end

    posts_controller_class = Class.new do
      class << self
        attr_reader :prepended_modules

        def prepend(mod)
          @prepended_modules ||= []
          @prepended_modules << mod
          super
        end
      end
    end

    post_item_excerpt_module = Module.new do
      class << self
        attr_reader :prepended_modules

        def prepend(mod)
          @prepended_modules ||= []
          @prepended_modules << mod
          super
        end
      end
    end

    basic_post_serializer_class = Class.new
    class << basic_post_serializer_class
      attr_reader :prepended_modules

      def prepend(mod)
        @prepended_modules ||= []
        @prepended_modules << mod
        super
      end
    end

    post_serializer_class = Class.new(basic_post_serializer_class) do
      class << self
        attr_reader :prepended_modules

        def prepend(mod)
          @prepended_modules ||= []
          @prepended_modules << mod
          super
        end

      end
    end

    topic_view_class = Class.new do
      class << self
        attr_reader :prepended_modules

        def prepend(mod)
          @prepended_modules ||= []
          @prepended_modules << mod
          super
        end

        def apply_custom_default_scope(&block)
          @custom_default_scopes ||= []
          @custom_default_scopes << block
        end

        def custom_default_scopes
          @custom_default_scopes || []
        end
      end
    end

    Object.const_set(:Category, category_class)
    Object.const_set(:ApplicationController, application_controller_class)
    Object.const_set(:PostsController, posts_controller_class)
    Object.const_set(:PostItemExcerpt, post_item_excerpt_module)
    Object.const_set(:BasicPostSerializer, basic_post_serializer_class)
    Object.const_set(:PostSerializer, post_serializer_class)
    Object.const_set(:SearchPostSerializer, Class.new(post_serializer_class))
    Object.const_set(:TopicView, topic_view_class)

    example.run
  ensure
    Object.send(:remove_const, :Category) if Object.const_defined?(:Category)
    Object.send(:remove_const, :ApplicationController) if Object.const_defined?(:ApplicationController)
    Object.send(:remove_const, :PostsController) if Object.const_defined?(:PostsController)
    Object.send(:remove_const, :PostItemExcerpt) if Object.const_defined?(:PostItemExcerpt)
    Object.send(:remove_const, :BasicPostSerializer) if Object.const_defined?(:BasicPostSerializer)
    Object.send(:remove_const, :PostSerializer) if Object.const_defined?(:PostSerializer)
    Object.send(:remove_const, :SearchPostSerializer) if Object.const_defined?(:SearchPostSerializer)
    Object.send(:remove_const, :TopicView) if Object.const_defined?(:TopicView)
    Object.const_set(:Category, original_category) if original_category
    Object.const_set(:ApplicationController, original_application_controller) if original_application_controller
    Object.const_set(:PostsController, original_posts_controller) if original_posts_controller
    Object.const_set(:PostItemExcerpt, original_post_item_excerpt) if original_post_item_excerpt
    Object.const_set(:BasicPostSerializer, original_basic_post_serializer) if original_basic_post_serializer
    Object.const_set(:PostSerializer, original_post_serializer) if original_post_serializer
    Object.const_set(:SearchPostSerializer, original_search_post_serializer) if original_search_post_serializer
    Object.const_set(:TopicView, original_topic_view) if original_topic_view
  end

  it "registers the category custom field, preload, and serializer hooks" do
    expect(plugin_instance).to receive(:register_category_custom_field_type)
      .with("guest_comment_delay_minutes_override", :integer)
    expect(plugin_instance).to receive(:register_preloaded_category_custom_fields)
      .with("guest_comment_delay_minutes_override")
    expect(plugin_instance).to receive(:add_to_serializer)
      .with(:post, :guest_hidden_placeholder, hash_including(:include_condition))
    expect(plugin_instance).to receive(:add_to_serializer)
      .with(:post, :guest_hidden_delay_minutes, hash_including(:include_condition))
    expect(plugin_instance).to receive(:add_to_serializer)
      .with(:topic_view, :guest_comment_delay_notice, hash_including(:include_condition))
    expect(plugin_instance).to receive(:add_to_serializer)
      .with(:topic_view, :guest_comment_delay_state, hash_including(:include_condition))

    described_class.register!(plugin_instance)

    expect(Category.registered_fields).to be_nil
    expect(ApplicationController.prepended_modules).to include(DiscourseGuestCommentDelay::RequestScopeExtension)
    expect(PostsController.prepended_modules).to include(DiscourseGuestCommentDelay::PostsControllerExtension)
    expect(PostItemExcerpt.prepended_modules).to include(DiscourseGuestCommentDelay::PostItemExcerptExtension)
    expect(TopicView.prepended_modules).to include(DiscourseGuestCommentDelay::TopicViewExtension)
    expect(TopicView.custom_default_scopes.length).to eq(1)
    expect(BasicPostSerializer.prepended_modules).to include(DiscourseGuestCommentDelay::PostSerializerExtension::Basic)
    expect(PostSerializer.prepended_modules).to include(DiscourseGuestCommentDelay::PostSerializerExtension::Post)
  end

  it "wires the registered TopicView scope and serializer callbacks to production entrypoints" do
    serializer_calls = []
    fake_plugin = Class.new do
      define_method(:initialize) { |calls| @calls = calls }
      define_method(:register_category_custom_field_type) { |*| }
      define_method(:register_preloaded_category_custom_fields) { |*| }
      define_method(:add_to_serializer) do |serializer, field, options = {}, &block|
        @calls << [serializer, field, options, block]
      end
    end.new(serializer_calls)

    described_class.register!(fake_plugin)

    scope = instance_double("Scope")
    topic_view = instance_double("TopicViewInstance")
    filtered_scope = instance_double("FilteredScope")
    allow(DiscourseGuestCommentDelay::TopicViewHook).to receive(:apply)
      .with(scope: scope, topic_view: topic_view)
      .and_return(filtered_scope)

    expect(TopicView.custom_default_scopes.first.call(scope, topic_view)).to eq(filtered_scope)

    notice_call = serializer_calls.find { |call| call[0] == :topic_view && call[1] == :guest_comment_delay_notice }
    notice = DiscourseGuestCommentDelay::TopicNotice.new(filtered: true, delay_minutes: 60)
    topic_serializer_context = Class.new do
      define_method(:initialize) { |object| @object = object }
      define_method(:object) { @object }
    end.new(Object.new)
    topic_serializer_context.object.instance_variable_set(:@guest_comment_delay_notice, notice)

    expect(topic_serializer_context.instance_exec(&notice_call[2].fetch(:include_condition))).to be(true)
    expect(topic_serializer_context.instance_exec(&notice_call[3])).to eq(notice.to_h)

    hidden_call = serializer_calls.find { |call| call[0] == :post && call[1] == :guest_hidden_delay_minutes }
    post = instance_double("Post")
    guardian = instance_double("Guardian")
    post_serializer_context = Class.new do
      define_method(:initialize) { |object, scope| @object = object; @scope = scope }
      define_method(:object) { @object }
      define_method(:scope) { @scope }
    end.new(post, guardian)

    allow(described_class).to receive(:guest_hidden_post?).with(post: post, scope: guardian).and_return(true)
    allow(described_class).to receive(:delay_minutes_for_post).with(post: post).and_return(180)

    expect(post_serializer_context.instance_exec(&hidden_call[2].fetch(:include_condition))).to be(true)
    expect(post_serializer_context.instance_exec(&hidden_call[3])).to eq(180)
  end
end
