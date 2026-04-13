# frozen_string_literal: true

RSpec.describe DiscourseGuestCommentDelay::EffectiveDelayResolver do
  ResolverFakeSettings = Struct.new(:guest_comment_delay_minutes)
  ResolverFakeCategory = Struct.new(:custom_fields)
  ResolverFakePost = Struct.new(:post_number, :created_at)

  let(:now) { Time.utc(2026, 4, 9, 6, 30, 0) }
  let(:settings) { ResolverFakeSettings.new(60) }
  let(:resolver) { described_class.new(site_settings: settings, now: now) }

  it "falls back to the global delay when category override is nil" do
    category = ResolverFakeCategory.new({})

    expect(resolver.effective_delay_minutes(category: category)).to eq(60)
  end

  it "returns zero when category override disables the restriction" do
    category = ResolverFakeCategory.new({ "guest_comment_delay_minutes_override" => 0 })

    expect(resolver.effective_delay_minutes(category: category)).to eq(0)
    expect(resolver.restriction_enabled?(category: category)).to be(false)
  end

  it "returns a positive category override when present" do
    category = ResolverFakeCategory.new({ "guest_comment_delay_minutes_override" => 180 })

    expect(resolver.effective_delay_minutes(category: category)).to eq(180)
  end

  it "ignores malformed string override values and falls back to global" do
    category = ResolverFakeCategory.new({ "guest_comment_delay_minutes_override" => "abc" })

    expect(resolver.effective_delay_minutes(category: category)).to eq(60)
  end

  it "ignores negative override values and falls back to global" do
    category = ResolverFakeCategory.new({ "guest_comment_delay_minutes_override" => -15 })

    expect(resolver.effective_delay_minutes(category: category)).to eq(60)
  end

  it "keeps the first post visible even when it is newer than the cutoff" do
    category = ResolverFakeCategory.new({})
    post = ResolverFakePost.new(1, now - 60)

    expect(resolver.visible_to_guest?(post: post, category: category)).to be(true)
  end

  it "treats a reply exactly at the cutoff as visible" do
    category = ResolverFakeCategory.new({})
    post = ResolverFakePost.new(2, now - (60 * 60))

    expect(resolver.visible_to_guest?(post: post, category: category)).to be(true)
  end

  it "hides a reply newer than the cutoff from guests" do
    category = ResolverFakeCategory.new({})
    post = ResolverFakePost.new(2, now - ((60 * 60) - 1))

    expect(resolver.visible_to_guest?(post: post, category: category)).to be(false)
  end

  it "shows all replies when the effective delay is disabled" do
    category = ResolverFakeCategory.new({ "guest_comment_delay_minutes_override" => 0 })
    post = ResolverFakePost.new(2, now - 60)

    expect(resolver.visible_to_guest?(post: post, category: category)).to be(true)
  end
end
