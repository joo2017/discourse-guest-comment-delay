# frozen_string_literal: true

RSpec.describe DiscourseGuestCommentDelay::TopicViewHook do
  let(:scope) { instance_double("Scope") }
  let(:topic_view) { Object.new }
  let(:filtered_scope) { instance_double("FilteredScope") }
  let(:notice) { DiscourseGuestCommentDelay::TopicNotice.new(filtered: true, delay_minutes: 60) }
  let(:result) { DiscourseGuestCommentDelay::TopicViewFilter::Result.new(scope: filtered_scope, notice: notice) }
  let(:filter) { instance_double(DiscourseGuestCommentDelay::TopicViewFilter) }

  it "stores notice metadata on the topic view and returns the filtered scope" do
    allow(filter).to receive(:apply).with(scope: scope, topic_view: topic_view).and_return(result)

    returned_scope = described_class.apply(scope: scope, topic_view: topic_view, filter: filter)

    expect(returned_scope).to eq(filtered_scope)
    expect(topic_view.instance_variable_get(:@guest_comment_delay_notice)&.to_h).to eq(notice.to_h)
  end
end
