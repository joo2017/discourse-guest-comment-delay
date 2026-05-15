# frozen_string_literal: true

RSpec.describe "guest quote redaction" do
  FakeQuoteCategory = Struct.new(:custom_fields)
  FakeQuoteTopic = Struct.new(:id, :category)
  FakeQuotePost = Struct.new(:topic_id, :post_number, :created_at, :topic, :cooked_value, :excerpt_value, keyword_init: true) do
    def cooked
      cooked_value
    end

    def excerpt(*)
      excerpt_value || cooked_value
    end
  end

  FakeQuoteGuardian = Struct.new(:anonymous?)

  let(:original_post) { Object.const_defined?(:Post) ? Post : nil }
  let(:original_site_setting) { Object.const_defined?(:SiteSetting) ? SiteSetting : nil }
  let(:category) { FakeQuoteCategory.new({}) }
  let(:topic) { FakeQuoteTopic.new(1171, category) }
  let(:hidden_post) do
    FakeQuotePost.new(
      topic_id: 1171,
      post_number: 12,
      created_at: Time.now,
      topic: topic,
      cooked_value: "<p>hidden secret</p>"
    )
  end

  before do
    Object.send(:remove_const, :Post) if Object.const_defined?(:Post)
    Object.send(:remove_const, :SiteSetting) if Object.const_defined?(:SiteSetting)

    hidden = hidden_post
    post_class = Class.new do
      define_singleton_method(:find_by) do |topic_id:, post_number:|
        topic_id == 1171 && post_number == 12 ? hidden : nil
      end
    end
    site_setting_class = Class.new do
      def self.guest_comment_delay_minutes = 60
      def self.guest_comment_delay_placeholder_text = "Hidden for %{delay_minutes} minutes"
    end

    Object.const_set(:Post, post_class)
    Object.const_set(:SiteSetting, site_setting_class)
  end

  after do
    Object.send(:remove_const, :Post) if Object.const_defined?(:Post)
    Object.send(:remove_const, :SiteSetting) if Object.const_defined?(:SiteSetting)
    Object.const_set(:Post, original_post) if original_post
    Object.const_set(:SiteSetting, original_site_setting) if original_site_setting
  end

  it "replaces quoted hidden replies in visible cooked HTML for anonymous users" do
    cooked = <<~HTML
      <p>visible intro</p>
      <aside class="quote" data-post="12" data-topic="1171">
        <div class="title">quoted:</div>
        <blockquote><p>hidden secret</p></blockquote>
      </aside>
    HTML

    redacted = DiscourseGuestCommentDelay.redact_hidden_quotes_for_guest(
      cooked: cooked,
      post: instance_double("Post"),
      scope: FakeQuoteGuardian.new(true)
    )

    expect(redacted).to include("visible intro")
    expect(redacted).to include("Hidden for 60 minutes")
    expect(redacted).not_to include("hidden secret")
  end

  it "keeps quoted hidden replies for logged-in users" do
    cooked = '<aside class="quote" data-post="12" data-topic="1171"><blockquote><p>hidden secret</p></blockquote></aside>'

    redacted = DiscourseGuestCommentDelay.redact_hidden_quotes_for_guest(
      cooked: cooked,
      post: instance_double("Post"),
      scope: FakeQuoteGuardian.new(false)
    )

    expect(redacted).to include("hidden secret")
  end

  it "decorates visible crawler posts that quote hidden replies" do
    visible_post = FakeQuotePost.new(
      topic_id: 1171,
      post_number: 13,
      created_at: Time.now,
      topic: topic,
      cooked_value: '<aside class="quote" data-post="12" data-topic="1171"><blockquote><p>hidden secret</p></blockquote></aside>',
      excerpt_value: 'hidden secret'
    )

    decorated = DiscourseGuestCommentDelay.decorate_post_for_guest(visible_post, user: nil)

    expect(decorated.cooked).to include("Hidden for 60 minutes")
    expect(decorated.cooked).not_to include("hidden secret")
  end
end
