# frozen_string_literal: true

RSpec.describe DiscourseGuestCommentDelay::TopicNotice do
  it "returns only safe topic-level metadata" do
    visible_after_at = Time.utc(2026, 4, 9, 16, 0, 0)
    notice = described_class.new(filtered: true, delay_minutes: 180, visible_after_at: visible_after_at)

    expect(notice.to_h).to eq(
      filtered: true,
      delay_minutes: 180,
      message_key: "guest_comment_delay.topic_notice",
      visible_after_at: "2026-04-09T16:00:00Z"
    )
  end
end
