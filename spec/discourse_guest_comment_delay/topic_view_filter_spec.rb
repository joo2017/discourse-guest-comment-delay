# frozen_string_literal: true

RSpec.describe DiscourseGuestCommentDelay::TopicViewFilter do
  FilterFakeGuard = Struct.new(:anonymous?)
  FilterFakeTopic = Struct.new(:category)
  FilterFakeTopicView = Struct.new(:guardian, :topic)
  FilterFakeCategory = Struct.new(:custom_fields)

  let(:scope) { instance_double("Scope") }
  let(:resolver) { instance_double(DiscourseGuestCommentDelay::EffectiveDelayResolver) }
  let(:filter) { described_class.new(resolver: resolver) }
  let(:category) { FilterFakeCategory.new({}) }
  let(:topic_view) { FilterFakeTopicView.new(FilterFakeGuard.new(true), FilterFakeTopic.new(category)) }
  let(:cutoff) { Time.utc(2026, 4, 9, 5, 30, 0) }
  let(:filtered_scope) { instance_double("FilteredScope") }
  let(:hidden_scope) { instance_double("HiddenScope") }
  let(:visible_after_at) { Time.utc(2026, 4, 9, 6, 15, 0) }

  it "does nothing for logged-in users" do
    logged_in_topic_view = FilterFakeTopicView.new(FilterFakeGuard.new(false), FilterFakeTopic.new(category))

    allow(resolver).to receive(:effective_delay_minutes).with(category: category).and_return(60)

    result = filter.apply(scope: scope, topic_view: logged_in_topic_view)

    expect(result.scope).to eq(scope)
    expect(result.notice).to be_nil
  end

  it "does nothing when the effective delay is disabled" do
    allow(resolver).to receive(:effective_delay_minutes).with(category: category).and_return(0)

    result = filter.apply(scope: scope, topic_view: topic_view)

    expect(result.scope).to eq(scope)
    expect(result.notice).to be_nil
  end

  it "detects anonymous hidden posts without removing them from the stream" do
    allow(resolver).to receive(:effective_delay_minutes).with(category: category).and_return(60)
    allow(resolver).to receive(:cutoff_time).with(category: category).and_return(cutoff)
    allow(scope).to receive(:where).with("posts.post_number > 1 AND posts.created_at > ?", cutoff).and_return(hidden_scope)
    allow(hidden_scope).to receive(:minimum).with(:created_at).and_return(visible_after_at - (60 * 60))
    allow(hidden_scope).to receive(:count).and_return(1)

    result = filter.apply(scope: scope, topic_view: topic_view)

    expect(result.scope).to eq(scope)
    expect(result.notice&.to_h).to eq(
      filtered: true,
      delay_minutes: 60,
      message_key: "guest_comment_delay.topic_notice",
      visible_after_at: "2026-04-09T06:15:00Z"
    )
  end

  it "suppresses the notice when no replies were actually filtered out" do
    allow(resolver).to receive(:effective_delay_minutes).with(category: category).and_return(60)
    allow(resolver).to receive(:cutoff_time).with(category: category).and_return(cutoff)
    allow(scope).to receive(:where).with("posts.post_number > 1 AND posts.created_at > ?", cutoff).and_return(hidden_scope)
    allow(hidden_scope).to receive(:minimum).with(:created_at).and_return(nil)
    allow(hidden_scope).to receive(:count).and_return(0)

    result = filter.apply(scope: scope, topic_view: topic_view)

    expect(result.scope).to eq(scope)
    expect(result.notice).to be_nil
  end
end
