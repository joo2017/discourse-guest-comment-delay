# frozen_string_literal: true

module DiscourseGuestCommentDelay
  module TopicViewExtension
    def initialize(*args, **kwargs)
      super

      @posts = redact_posts_for_guest(@posts) if instance_variable_defined?(:@posts) && !@skip_post_loading
    end

    def crawler_posts
      redact_loaded_posts_for_guest(super)
    end

    def posts
      posts = super
      return posts if relation_like_posts?(posts)

      redact_posts_for_guest(posts)
    end

    def recent_posts
      redact_loaded_posts_for_guest(super)
    end

    def summary(opts = {})
      return DiscourseGuestCommentDelay.placeholder_text(delay_minutes: DiscourseGuestCommentDelay.delay_minutes_for_post(post: desired_post)) if desired_post && DiscourseGuestCommentDelay.guest_hidden_post_for_user?(post: desired_post, user: @user)

      super
    end

    private

    def redact_posts_for_guest(posts)
      return posts if relation_like_posts?(posts)

      posts = Array(posts)
      posts.each { |post| post.topic = topic if post.respond_to?(:topic=) && post.respond_to?(:topic) && post.topic.nil? }
      DiscourseGuestCommentDelay.decorate_hidden_posts_for_guest(posts, user: @user)
    end

    def redact_loaded_posts_for_guest(posts)
      posts = Array(posts)
      posts.each { |post| post.topic = topic if post.respond_to?(:topic=) && post.respond_to?(:topic) && post.topic.nil? }
      DiscourseGuestCommentDelay.decorate_hidden_posts_for_guest(posts, user: @user)
    end

    def relation_like_posts?(posts)
      posts.respond_to?(:includes)
    end
  end
end
