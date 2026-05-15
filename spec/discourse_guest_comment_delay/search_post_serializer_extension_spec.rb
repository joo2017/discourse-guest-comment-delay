# frozen_string_literal: true

RSpec.describe DiscourseGuestCommentDelay::SearchPostSerializerExtension do
  FakeSearchCategory = Struct.new(:custom_fields)
  FakeSearchTopic = Struct.new(:category)
  FakeSearchPost = Struct.new(:post_number, :created_at, :topic, keyword_init: true)
  FakeSearchGuardian = Struct.new(:anonymous?)

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

  it "returns placeholder text for anonymous search blurbs of hidden replies" do
    serializer_class = Class.new do
      prepend DiscourseGuestCommentDelay::SearchPostSerializerExtension

      attr_reader :object, :scope

      def initialize(object, scope)
        @object = object
        @scope = scope
      end

      def blurb
        "hidden secret search blurb"
      end
    end

    post = FakeSearchPost.new(
      post_number: 2,
      created_at: Time.now,
      topic: FakeSearchTopic.new(FakeSearchCategory.new({}))
    )

    expect(serializer_class.new(post, FakeSearchGuardian.new(true)).blurb).to eq("Hidden for 60 minutes")
  end

  it "keeps search blurbs for logged-in users" do
    serializer_class = Class.new do
      prepend DiscourseGuestCommentDelay::SearchPostSerializerExtension

      attr_reader :object, :scope

      def initialize(object, scope)
        @object = object
        @scope = scope
      end

      def blurb
        "visible search blurb"
      end
    end

    post = FakeSearchPost.new(
      post_number: 2,
      created_at: Time.now,
      topic: FakeSearchTopic.new(FakeSearchCategory.new({}))
    )

    expect(serializer_class.new(post, FakeSearchGuardian.new(false)).blurb).to eq("visible search blurb")
  end
end
