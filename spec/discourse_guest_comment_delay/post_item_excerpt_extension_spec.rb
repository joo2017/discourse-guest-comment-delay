# frozen_string_literal: true

RSpec.describe DiscourseGuestCommentDelay::PostItemExcerptExtension do
  FakeExcerptCategory = Struct.new(:custom_fields)
  FakeExcerptTopic = Struct.new(:id, :category)
  FakeExcerptPost = Struct.new(:topic_id, :category_id, :post_number, :created_at, :topic, :cooked_value, keyword_init: true) do
    def cooked
      cooked_value
    end

    def raw
      cooked_value
    end
  end
  FakeExcerptGuardian = Struct.new(:anonymous?)

  let(:original_site_setting) { Object.const_defined?(:SiteSetting) ? SiteSetting : nil }

  before do
    Object.send(:remove_const, :SiteSetting) if Object.const_defined?(:SiteSetting)
    site_setting_class = Class.new do
      def self.guest_comment_delay_minutes = 60
      def self.guest_comment_delay_placeholder_text = "Hidden for %{delay_minutes} minutes"
    end
    Object.const_set(:SiteSetting, site_setting_class)
  end

  after do
    Object.send(:remove_const, :SiteSetting) if Object.const_defined?(:SiteSetting)
    Object.const_set(:SiteSetting, original_site_setting) if original_site_setting
  end

  it "redacts anonymous PostItemExcerpt summaries for hidden reply-like records" do
    serializer_class = Class.new do
      prepend DiscourseGuestCommentDelay::PostItemExcerptExtension

      attr_reader :object, :scope

      def initialize(object, scope)
        @object = object
        @scope = scope
      end

      def cooked
        object.cooked
      end

      def excerpt
        "hidden activity secret"
      end
    end

    post = FakeExcerptPost.new(
      post_number: 2,
      created_at: Time.now,
      topic: FakeExcerptTopic.new(1171, FakeExcerptCategory.new({})),
      cooked_value: "<p>hidden activity secret</p>"
    )

    serializer = serializer_class.new(post, FakeExcerptGuardian.new(true))

    expect(serializer.cooked).to include("Hidden for 60 minutes")
    expect(serializer.excerpt).to eq("Hidden for 60 minutes")
    expect(serializer.excerpt).not_to include("hidden activity secret")
  end

  it "keeps PostItemExcerpt summaries for logged-in users" do
    serializer_class = Class.new do
      prepend DiscourseGuestCommentDelay::PostItemExcerptExtension

      attr_reader :object, :scope

      def initialize(object, scope) = (@object = object; @scope = scope)
      def cooked = object.cooked
      def excerpt = "visible activity summary"
    end

    post = FakeExcerptPost.new(
      post_number: 2,
      created_at: Time.now,
      topic: FakeExcerptTopic.new(1171, FakeExcerptCategory.new({})),
      cooked_value: "<p>visible activity summary</p>"
    )

    expect(serializer_class.new(post, FakeExcerptGuardian.new(false)).excerpt).to eq("visible activity summary")
  end
end
