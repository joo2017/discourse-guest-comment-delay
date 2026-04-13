# frozen_string_literal: true

require "yaml"

RSpec.describe "plugin configuration contracts" do
  let(:settings_path) { File.expand_path("../../config/settings.yml", __dir__) }
  let(:server_locale_path) { File.expand_path("../../config/locales/server.en.yml", __dir__) }
  let(:client_locale_path) { File.expand_path("../../config/locales/client.en.yml", __dir__) }

  it "defines the guest delay site setting with default 60 and min 0" do
    settings = YAML.safe_load_file(settings_path)
    guest_delay = settings.fetch("plugins").fetch("guest_comment_delay_minutes")

    expect(guest_delay).to include(
      "default" => 60,
      "min" => 0,
      "client" => false
    )
  end

  it "defines the configurable placeholder text site setting" do
    settings = YAML.safe_load_file(settings_path)
    placeholder_text = settings.fetch("plugins").fetch("guest_comment_delay_placeholder_text")

    expect(placeholder_text).to include(
      "default" => "非会员无法阅读发表后%{delay_duration}内的评论。登录后可立即查看^^",
      "type" => "string",
      "client" => false
    )
  end

  it "defines server locale text for the site setting and category help" do
    locale = YAML.safe_load_file(server_locale_path)
    en = locale.fetch("en")

    expect(en.fetch("site_settings").fetch("guest_comment_delay_minutes")).not_to be_empty
    expect(en.fetch("site_settings").fetch("guest_comment_delay_placeholder_text")).not_to be_empty
    expect(en.fetch("guest_comment_delay").fetch("category_override_label")).not_to be_empty
    expect(en.fetch("guest_comment_delay").fetch("category_override_description")).not_to be_empty
  end

  it "defines client locale text for the guest notice and category editor" do
    locale = YAML.safe_load_file(client_locale_path)
    guest_delay = locale.fetch("en").fetch("js").fetch("guest_comment_delay")

    expect(guest_delay.fetch("topic_notice")).not_to be_empty
    expect(guest_delay.fetch("category_override_label")).not_to be_empty
    expect(guest_delay.fetch("category_override_description")).not_to be_empty
  end
end
