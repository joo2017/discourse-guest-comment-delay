# frozen_string_literal: true

module DiscourseGuestCommentDelay
  class GuestTopicState
    def initialize(topic_view:, resolver: EffectiveDelayResolver.new)
      @topic_view = topic_view
      @resolver = resolver
    end

    def active?
      delay_minutes.positive? && visible_posts_count < total_posts_count
    end

    def to_h
      {
        active: active?,
        delay_minutes: delay_minutes,
        visible_posts_count: visible_posts_count,
        visible_reply_count: visible_reply_count,
        visible_last_posted_at: visible_last_posted_at,
        visible_after_at: visible_after_at&.iso8601
      }
    end

    def visible_after_at
      return nil unless active?
      return nil unless defined?(Post)
      return nil unless @topic_view.respond_to?(:topic)

      hidden_created_at = Post.where(topic_id: @topic_view.topic.id)
        .where("post_number > 1 AND created_at > ?", @resolver.cutoff_time(category: topic_category))
        .minimum(:created_at)

      return nil if hidden_created_at.nil?

      hidden_created_at + (delay_minutes * 60)
    end

    private

    def delay_minutes
      @delay_minutes ||= @resolver.effective_delay_minutes(category: topic_category)
    end

    def topic_category
      return nil unless @topic_view.respond_to?(:topic)

      @topic_view.topic&.category
    end

    def total_posts_count
      return @topic_view.topic.posts_count.to_i if @topic_view.respond_to?(:topic) && @topic_view.topic.respond_to?(:posts_count)

      visible_posts_count
    end

    def visible_posts_count
      visible_posts.size
    end

    def visible_reply_count
      visible_posts.count { |post| post.respond_to?(:post_number) && post.post_number.to_i > 1 }
    end

    def visible_last_posted_at
      visible_posts.map { |post| post.respond_to?(:created_at) ? post.created_at : nil }.compact.max
    end

    def visible_posts
      return [] unless @topic_view.respond_to?(:posts)

      Array(@topic_view.posts)
    end
  end
end
