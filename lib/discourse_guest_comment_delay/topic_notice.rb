# frozen_string_literal: true

require "time"

module DiscourseGuestCommentDelay
  class TopicNotice
    attr_reader :filtered, :delay_minutes, :message_key, :visible_after_at

    def initialize(filtered:, delay_minutes:, message_key: "guest_comment_delay.topic_notice", visible_after_at: nil)
      @filtered = filtered
      @delay_minutes = delay_minutes
      @message_key = message_key
      @visible_after_at = visible_after_at
    end

    def to_h
      {
        filtered: filtered,
        delay_minutes: delay_minutes,
        message_key: message_key,
        visible_after_at: visible_after_at&.iso8601
      }
    end
  end
end
