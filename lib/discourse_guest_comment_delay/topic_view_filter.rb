# frozen_string_literal: true

module DiscourseGuestCommentDelay
  class TopicViewFilter
    FILTER_SQL = "posts.post_number = 1 OR posts.created_at <= ?"

    Result = Struct.new(:scope, :notice, keyword_init: true)

    def initialize(resolver: EffectiveDelayResolver.new)
      @resolver = resolver
    end

    def apply(scope:, topic_view:)
      category = topic_category(topic_view)
      delay_minutes = @resolver.effective_delay_minutes(category: category)

      return Result.new(scope: scope, notice: nil) unless anonymous?(topic_view)
      return Result.new(scope: scope, notice: nil) if delay_minutes.zero?

      cutoff_time = @resolver.cutoff_time(category: category)
      hidden_count = count_scope(hidden_scope(scope: scope, cutoff_time: cutoff_time))
      filtered = hidden_count.nil? ? false : hidden_count.positive?

      Result.new(
        scope: scope,
        notice: filtered ? TopicNotice.new(filtered: true, delay_minutes: delay_minutes, visible_after_at: visible_after_at(scope: scope, cutoff_time: cutoff_time, delay_minutes: delay_minutes)) : nil
      )
    end

    private

    def anonymous?(topic_view)
      topic_view.respond_to?(:guardian) && topic_view.guardian.respond_to?(:anonymous?) && topic_view.guardian.anonymous?
    end

    def topic_category(topic_view)
      return topic_view.topic.category if topic_view.respond_to?(:topic) && topic_view.topic.respond_to?(:category)

      nil
    end

    def count_scope(scope)
      return scope.count if scope.respond_to?(:count)

      nil
    end

    def visible_after_at(scope:, cutoff_time:, delay_minutes:)
      return nil unless scope.respond_to?(:where)

      hidden_created_at = hidden_scope(scope: scope, cutoff_time: cutoff_time).minimum(:created_at)
      return nil if hidden_created_at.nil?

      hidden_created_at + (delay_minutes * 60)
    end

    def hidden_scope(scope:, cutoff_time:)
      scope.where("posts.post_number > 1 AND posts.created_at > ?", cutoff_time)
    end
  end
end
