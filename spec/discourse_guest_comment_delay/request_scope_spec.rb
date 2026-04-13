# frozen_string_literal: true

RSpec.describe DiscourseGuestCommentDelay do
  it "tracks request scope user only within the block" do
    marker_user = Object.new

    expect(described_class.request_scope_active?).to be(false)
    expect(described_class.request_scope_user).to be_nil

    described_class.with_request_scope(marker_user) do
      expect(described_class.request_scope_active?).to be(true)
      expect(described_class.request_scope_user).to eq(marker_user)
    end

    expect(described_class.request_scope_active?).to be(false)
    expect(described_class.request_scope_user).to be_nil
  end

  it "redacts reduce_cooked fragments only for guest-scoped hidden posts" do
    post = instance_double("Post")
    children = instance_double("Children")
    fragment = instance_double("Fragment", children: children)

    allow(described_class).to receive(:guest_hidden_post_for_user?).with(post: post, user: nil).and_return(true)
    allow(described_class).to receive(:delay_minutes_for_post).with(post: post).and_return(180)
    allow(described_class).to receive(:placeholder_html).with(delay_minutes: 180).and_return("<div>placeholder</div>")
    expect(children).to receive(:remove)
    expect(fragment).to receive(:add_child).with("<div>placeholder</div>")

    described_class.with_request_scope(nil) do
      described_class.reduce_cooked_fragment_for_guest!(fragment: fragment, post: post)
    end
  end
end
