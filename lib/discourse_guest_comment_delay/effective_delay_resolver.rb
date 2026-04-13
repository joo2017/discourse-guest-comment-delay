# frozen_string_literal: true

module DiscourseGuestCommentDelay
  class EffectiveDelayResolver
    def initialize(site_settings: nil, now: Time.now)
      @site_settings = site_settings
      @now = now
    end

    def effective_delay_minutes(category: nil)
      override = category_override_minutes(category)
      return override unless override.nil?

      global_delay_minutes
    end

    def restriction_enabled?(category: nil)
      effective_delay_minutes(category: category).positive?
    end

    def cutoff_time(category: nil)
      @now - (effective_delay_minutes(category: category) * 60)
    end

    def visible_to_guest?(post:, category: nil)
      return true if first_post?(post)
      return true unless restriction_enabled?(category: category)

      post.created_at <= cutoff_time(category: category)
    end

    private

    def first_post?(post)
      post.respond_to?(:post_number) && post.post_number.to_i == 1
    end

    def category_override_minutes(category)
      return nil unless category.respond_to?(:custom_fields)

      raw_value = category.custom_fields[DiscourseGuestCommentDelay::CATEGORY_CUSTOM_FIELD]
      return nil if raw_value.nil? || raw_value == ""

      return raw_value if raw_value.is_a?(Integer) && raw_value >= 0
      return nil unless raw_value.to_s.match?(/\A\d+\z/)

      raw_value.to_i
    end

    def global_delay_minutes
      if @site_settings && @site_settings.respond_to?(:guest_comment_delay_minutes)
        @site_settings.guest_comment_delay_minutes.to_i
      elsif defined?(SiteSetting) && SiteSetting.respond_to?(:guest_comment_delay_minutes)
        SiteSetting.guest_comment_delay_minutes.to_i
      else
        60
      end
    end
  end
end
