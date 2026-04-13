# frozen_string_literal: true

RSpec.describe DiscourseGuestCommentDelay::GuestTopicState do
  FakePost = Struct.new(:post_number, :created_at)
  FakeTopic = Struct.new(:id, :posts_count, :category)
  FakeTopicView = Struct.new(:posts, :topic)
  FakeCategory = Struct.new(:custom_fields)

  let(:resolver) { instance_double(DiscourseGuestCommentDelay::EffectiveDelayResolver) }
  let(:original_post) { Object.const_defined?(:Post) ? Post : nil }

  after do
    Object.send(:remove_const, :Post) if Object.const_defined?(:Post)
    Object.const_set(:Post, original_post) if original_post
  end

  it "reports guest-safe summary fields for visible posts" do
    first_post = FakePost.new(1, Time.utc(2026, 4, 1, 12, 0, 0))
    visible_reply = FakePost.new(2, Time.utc(2026, 4, 7, 12, 0, 0))
    category = FakeCategory.new({})
    topic_view = FakeTopicView.new([first_post, visible_reply], FakeTopic.new(3, 3, category))

    allow(resolver).to receive(:effective_delay_minutes).with(category: category).and_return(60)
    allow(resolver).to receive(:cutoff_time).with(category: category).and_return(Time.utc(2026, 4, 7, 11, 0, 0))

    hidden_relation = instance_double("HiddenRelation")
    post_class = Class.new
    allow(post_class).to receive(:where).with(topic_id: 3).and_return(hidden_relation)
    allow(hidden_relation).to receive(:where).with("post_number > 1 AND created_at > ?", Time.utc(2026, 4, 7, 11, 0, 0)).and_return(hidden_relation)
    allow(hidden_relation).to receive(:minimum).with(:created_at).and_return(Time.utc(2026, 4, 7, 11, 30, 0))
    Object.const_set(:Post, post_class)

    expect(described_class.new(topic_view: topic_view, resolver: resolver).to_h).to eq(
      active: true,
      delay_minutes: 60,
      visible_posts_count: 2,
      visible_reply_count: 1,
      visible_last_posted_at: Time.utc(2026, 4, 7, 12, 0, 0),
      visible_after_at: "2026-04-07T12:30:00Z"
    )
  end

  it "reports inactive state when no guest filtering occurred" do
    category = FakeCategory.new({})
    topic_view = FakeTopicView.new([], FakeTopic.new(3, 0, category))

    allow(resolver).to receive(:effective_delay_minutes).with(category: category).and_return(60)
    allow(resolver).to receive(:cutoff_time).with(category: category).never

    expect(described_class.new(topic_view: topic_view, resolver: resolver).to_h).to eq(
      active: false,
      delay_minutes: 60,
      visible_posts_count: 0,
      visible_reply_count: 0,
      visible_last_posted_at: nil,
      visible_after_at: nil
    )
  end
end
