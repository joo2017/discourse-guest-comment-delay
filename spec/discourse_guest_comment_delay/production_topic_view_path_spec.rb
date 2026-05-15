# frozen_string_literal: true

RSpec.describe "guest comment delay production topic view path" do
  FakeProductionCategory = Struct.new(:custom_fields)
  FakeProductionTopic = Struct.new(:category, :posts_count, :id)
  FakeProductionGuardian = Struct.new(:anonymous?)
  FakeProductionHiddenScope = Struct.new(:created_at) do
    def count
      1
    end

    def minimum(column)
      return created_at if column == :created_at

      nil
    end
  end

  FakeProductionScope = Struct.new(:hidden_scope) do
    def where(*args)
      return hidden_scope if args.first == "posts.post_number > 1 AND posts.created_at > ?"

      self
    end
  end

  FakeProductionPost = Struct.new(:post_number, :created_at, :topic, :body, keyword_init: true) do
    def topic=(value)
      self[:topic] = value
    end

    def cooked
      "<p>#{body}</p>"
    end

    def raw
      body
    end

    def excerpt(*)
      body
    end
  end

  around do |example|
    originals = {}
    %i[ApplicationController PostsController BasicPostSerializer PostSerializer TopicView SiteSetting].each do |name|
      originals[name] = Object.const_get(name) if Object.const_defined?(name)
      Object.send(:remove_const, name) if Object.const_defined?(name)
    end

    application_controller_class = Class.new
    posts_controller_class = Class.new
    basic_post_serializer_class = Class.new
    post_serializer_class = Class.new(basic_post_serializer_class)

    site_setting_class = Class.new do
      def self.guest_comment_delay_minutes
        60
      end

      def self.guest_comment_delay_placeholder_text
        "Hidden for %{delay_minutes} minutes"
      end
    end

    topic_view_class = Class.new do
      class << self
        def apply_custom_default_scope(&block)
          custom_default_scopes << block
        end

        def custom_default_scopes
          @custom_default_scopes ||= []
        end
      end

      attr_reader :topic, :posts, :guardian

      def initialize(topic, user, options = {})
        @topic = topic
        @user = user
        @guardian = FakeProductionGuardian.new(user.nil?)
        @posts = options.fetch(:posts)
        scope = FakeProductionScope.new(FakeProductionHiddenScope.new(@posts.last.created_at))
        self.class.custom_default_scopes.each { |block| block.call(scope, self) }
      end
    end

    Object.const_set(:ApplicationController, application_controller_class)
    Object.const_set(:PostsController, posts_controller_class)
    Object.const_set(:BasicPostSerializer, basic_post_serializer_class)
    Object.const_set(:PostSerializer, post_serializer_class)
    Object.const_set(:TopicView, topic_view_class)
    Object.const_set(:SiteSetting, site_setting_class)

    example.run
  ensure
    %i[ApplicationController PostsController BasicPostSerializer PostSerializer TopicView SiteSetting].each do |name|
      Object.send(:remove_const, name) if Object.const_defined?(name)
      Object.const_set(name, originals[name]) if originals.key?(name)
    end
  end

  it "redacts anonymous loaded posts through the registered TopicView lifecycle without removing shells" do
    serializer_calls = []
    plugin_instance = Class.new do
      define_method(:initialize) { |calls| @calls = calls }
      define_method(:register_category_custom_field_type) { |*| }
      define_method(:register_preloaded_category_custom_fields) { |*| }
      define_method(:add_to_serializer) { |*args, &block| @calls << [*args, block] }
    end.new(serializer_calls)

    DiscourseGuestCommentDelay.register!(plugin_instance)

    topic = FakeProductionTopic.new(FakeProductionCategory.new({}), 2, 1171)
    first_post = FakeProductionPost.new(post_number: 1, created_at: Time.now, topic: topic, body: "visible first post")
    hidden_reply = FakeProductionPost.new(post_number: 2, created_at: Time.now, topic: nil, body: "LEAK CHECK FRESH SECRET 20260409T2308Z")

    topic_view = TopicView.new(topic, nil, posts: [first_post, hidden_reply])

    expect(topic_view.posts.map(&:post_number)).to eq([1, 2])
    expect(topic_view.posts.last.topic).to eq(topic)
    expect(topic_view.posts.first.raw).to eq("visible first post")
    expect(topic_view.posts.last.raw).to eq("Hidden for 60 minutes")
    expect(topic_view.posts.last.cooked).to include("guest-comment-delay-placeholder")
    expect(topic_view.posts.last.cooked).not_to include("LEAK CHECK FRESH SECRET")
    expect(topic_view.posts.last.excerpt).to eq("Hidden for 60 minutes")
    expect(topic_view.instance_variable_get(:@guest_comment_delay_notice)&.to_h).to include(
      filtered: true,
      delay_minutes: 60
    )
    expect(serializer_calls.any? { |serializer, field, *_| serializer == :topic_view && field == :guest_comment_delay_notice }).to be(true)
  end

  it "leaves logged-in topic views unchanged" do
    plugin_instance = Class.new do
      def register_category_custom_field_type(*) = nil
      def register_preloaded_category_custom_fields(*) = nil
      def add_to_serializer(*) = nil
    end.new

    DiscourseGuestCommentDelay.register!(plugin_instance)

    topic = FakeProductionTopic.new(FakeProductionCategory.new({}), 2, 1171)
    reply = FakeProductionPost.new(post_number: 2, created_at: Time.now, topic: topic, body: "logged in visible reply")

    topic_view = TopicView.new(topic, Object.new, posts: [reply])

    expect(topic_view.posts.first.raw).to eq("logged in visible reply")
    expect(topic_view.posts.first.cooked).to include("logged in visible reply")
    expect(topic_view.instance_variable_get(:@guest_comment_delay_notice)).to be_nil
  end
end
