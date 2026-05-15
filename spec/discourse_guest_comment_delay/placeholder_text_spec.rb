# frozen_string_literal: true

RSpec.describe DiscourseGuestCommentDelay do
  around do |example|
    original_site_setting = Object.const_defined?(:SiteSetting) ? SiteSetting : nil
    Object.send(:remove_const, :SiteSetting) if Object.const_defined?(:SiteSetting)

    site_setting_class = Class.new do
      class << self
        attr_accessor :guest_comment_delay_placeholder_text
      end
    end

    Object.const_set(:SiteSetting, site_setting_class)
    example.run
  ensure
    Object.send(:remove_const, :SiteSetting) if Object.const_defined?(:SiteSetting)
    Object.const_set(:SiteSetting, original_site_setting) if original_site_setting
  end

  it "uses the configurable template with delay_duration interpolation" do
    SiteSetting.guest_comment_delay_placeholder_text = "非会员无法阅读发表后%{delay_duration}内的评论。登录后可立即查看^^"

    expect(described_class.placeholder_text(delay_minutes: 180)).to eq(
      "非会员无法阅读发表后3小时内的评论。登录后可立即查看^^"
    )
  end

  it "supports direct delay_minutes interpolation for custom templates" do
    SiteSetting.guest_comment_delay_placeholder_text = "游客需等待%{delay_minutes}分钟，登录后可立即查看^^"

    expect(described_class.placeholder_text(delay_minutes: 45)).to eq(
      "游客需等待45分钟，登录后可立即查看^^"
    )
  end

  it "leaves literal percent signs untouched" do
    SiteSetting.guest_comment_delay_placeholder_text = "100% hidden for %{delay_minutes} minutes"

    expect(described_class.placeholder_text(delay_minutes: 45)).to eq(
      "100% hidden for 45 minutes"
    )
  end

  it "leaves unknown placeholders untouched" do
    SiteSetting.guest_comment_delay_placeholder_text = "Hidden for %{delay_duration}; unknown %{reason}"

    expect(described_class.placeholder_text(delay_minutes: 120)).to eq(
      "Hidden for 2小时; unknown %{reason}"
    )
  end

  it "combines literal percent signs, supported placeholders, and unknown placeholders safely" do
    SiteSetting.guest_comment_delay_placeholder_text = "100% hidden for %{delay_duration} (%{delay_minutes} minutes); unknown %{foo}"

    expect(described_class.placeholder_text(delay_minutes: 90)).to eq(
      "100% hidden for 90分钟 (90 minutes); unknown %{foo}"
    )
  end
end
