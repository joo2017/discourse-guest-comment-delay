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
end
