# frozen_string_literal: true

module DiscourseGuestCommentDelay
  class TopicViewHook
    class << self
      def apply(scope:, topic_view:, filter: TopicViewFilter.new)
        result = filter.apply(scope: scope, topic_view: topic_view)
        topic_view.instance_variable_set(:@guest_comment_delay_notice, result.notice)
        result.scope
      end
    end
  end
end
