# frozen_string_literal: true

RSpec.describe "topic notice connector contract" do
  let(:connector_path) do
    File.expand_path(
      "../../assets/javascripts/discourse/connectors/topic-above-posts/guest-comment-delay-notice.gjs",
      __dir__
    )
  end

  it "defines a topic-above-posts connector for guest notice rendering" do
    source = File.read(connector_path)

    expect(File.exist?(connector_path)).to be(true)
    expect(source).to include("@model.guest_comment_delay_notice")
    expect(source).to include('resolveDelayMinutes')
    expect(source).to include('formatDelayDurationZh')
    expect(source).to include('buildGuestNoticeZh')
    expect(source).to include('登录后可立即查看')
    expect(source).to include('alert alert-info')
  end
end
