# frozen_string_literal: true

RSpec.describe DiscourseGuestCommentDelay::TopicViewHook do
  it "stores notice metadata on the topic view, which drives serializer inclusion without extra scope gating" do
    topic_view = Object.new
    notice = DiscourseGuestCommentDelay::TopicNotice.new(filtered: true, delay_minutes: 60)

    topic_view.instance_variable_set(:@guest_comment_delay_notice, notice)

    expect(topic_view.instance_variable_get(:@guest_comment_delay_notice)&.to_h).to eq(
      filtered: true,
      delay_minutes: 60,
      message_key: "guest_comment_delay.topic_notice",
      visible_after_at: nil
    )
  end
end
