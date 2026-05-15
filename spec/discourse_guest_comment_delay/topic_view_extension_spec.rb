# frozen_string_literal: true

RSpec.describe DiscourseGuestCommentDelay::TopicViewExtension do
  FakeTopicViewExtensionTopic = Struct.new(:category)
  FakeTopicViewExtensionCategory = Struct.new(:custom_fields)
  FakeTopicViewExtensionPost = Struct.new(:post_number, :created_at, :topic, keyword_init: true) do
    def topic=(value)
      self[:topic] = value
    end
  end

  FakeTopicViewExtensionRelation = Struct.new(:posts, :included_associations) do
    def includes(associations)
      self.included_associations = associations
      self
    end

    def to_a
      posts
    end

    def each(&block)
      posts.each(&block)
    end
  end

  let(:original_site_setting) { Object.const_defined?(:SiteSetting) ? SiteSetting : nil }

  before do
    Object.send(:remove_const, :SiteSetting) if Object.const_defined?(:SiteSetting)

    site_setting_class = Class.new do
      def self.guest_comment_delay_minutes
        60
      end

      def self.guest_comment_delay_placeholder_text
        "Hidden for %{delay_minutes} minutes"
      end
    end

    Object.const_set(:SiteSetting, site_setting_class)
  end

  after do
    Object.send(:remove_const, :SiteSetting) if Object.const_defined?(:SiteSetting)
    Object.const_set(:SiteSetting, original_site_setting) if original_site_setting
  end

  it "redacts direct TopicView posts for anonymous crawler, print, and RSS render paths" do
    category = FakeTopicViewExtensionCategory.new({})
    topic = FakeTopicViewExtensionTopic.new(category)
    hidden_reply = FakeTopicViewExtensionPost.new(
      post_number: 2,
      created_at: Time.now,
      topic: nil
    )

    topic_view_class = Class.new do
      prepend DiscourseGuestCommentDelay::TopicViewExtension

      attr_reader :topic

      def initialize(topic, posts)
        @topic = topic
        @posts = posts
        @user = nil
      end

      def posts
        @posts
      end

      def crawler_posts
        @posts
      end
    end

    redacted_post = topic_view_class.new(topic, [hidden_reply]).posts.first

    expect(redacted_post.topic).to eq(topic)
    expect(redacted_post.cooked).to include("Hidden for 60 minutes")
    expect(redacted_post.raw).to eq("Hidden for 60 minutes")
    expect(redacted_post.excerpt).to eq("Hidden for 60 minutes")
  end

  it "redacts posts read after TopicView initialization" do
    category = FakeTopicViewExtensionCategory.new({})
    topic = FakeTopicViewExtensionTopic.new(category)
    hidden_reply = FakeTopicViewExtensionPost.new(
      post_number: 2,
      created_at: Time.now,
      topic: nil
    )

    topic_view_class = Class.new do
      prepend DiscourseGuestCommentDelay::TopicViewExtension

      attr_reader :topic

      def initialize(topic)
        @topic = topic
        @user = nil
      end

      def load_posts(posts)
        @posts = posts
      end

      def posts
        @posts
      end

      def crawler_posts
        @posts
      end
    end

    topic_view = topic_view_class.new(topic)
    topic_view.load_posts([hidden_reply])

    redacted_post = topic_view.posts.first

    expect(redacted_post.topic).to eq(topic)
    expect(redacted_post.cooked).to include("Hidden for 60 minutes")
    expect(redacted_post.raw).to eq("Hidden for 60 minutes")
  end

  it "preserves relation-like posts during preload hooks" do
    relation = FakeTopicViewExtensionRelation.new

    topic_view_class = Class.new do
      prepend DiscourseGuestCommentDelay::TopicViewExtension

      def initialize(posts)
        @posts = posts
        @user = nil
      end

      def posts
        @posts
      end

      def crawler_posts
        @posts
      end
    end

    topic_view = topic_view_class.new(relation)
    preloaded_posts = topic_view.posts.includes(event: :image_upload)

    expect(preloaded_posts).to equal(relation)
    expect(preloaded_posts).to respond_to(:includes)
    expect(preloaded_posts.included_associations).to eq(event: :image_upload)
  end

  it "redacts relation-like crawler posts after materializing them" do
    category = FakeTopicViewExtensionCategory.new({})
    topic = FakeTopicViewExtensionTopic.new(category)
    hidden_reply = FakeTopicViewExtensionPost.new(
      post_number: 2,
      created_at: Time.now,
      topic: nil
    )
    relation = FakeTopicViewExtensionRelation.new([hidden_reply])

    topic_view_class = Class.new do
      prepend DiscourseGuestCommentDelay::TopicViewExtension

      attr_reader :topic

      def initialize(topic, posts)
        @topic = topic
        @posts = posts
        @user = nil
      end

      def posts
        @posts
      end

      def crawler_posts
        @posts
      end
    end

    redacted_posts = topic_view_class.new(topic, relation).crawler_posts
    preloaded_posts = topic_view_class.new(topic, relation).posts.includes(event: :image_upload)

    expect(redacted_posts).to be_an(Array)
    expect(redacted_posts.first.topic).to eq(topic)
    expect(redacted_posts.first.cooked).to include("Hidden for 60 minutes")
    expect(redacted_posts.first.raw).to eq("Hidden for 60 minutes")
    expect(redacted_posts.first.excerpt).to eq("Hidden for 60 minutes")
    expect(preloaded_posts).to equal(relation)
    expect(preloaded_posts.included_associations).to eq(event: :image_upload)
  end
end
