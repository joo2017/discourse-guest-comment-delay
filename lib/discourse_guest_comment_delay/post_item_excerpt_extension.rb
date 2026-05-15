# frozen_string_literal: true

module DiscourseGuestCommentDelay
  module PostItemExcerptExtension
    def cooked
      return DiscourseGuestCommentDelay.placeholder_html(delay_minutes: guest_hidden_delay_minutes) if guest_hidden_placeholder?

      value = super
      DiscourseGuestCommentDelay.redact_hidden_quotes_for_guest(cooked: value, post: object, scope: scope)
    end

    def excerpt
      return DiscourseGuestCommentDelay.placeholder_text(delay_minutes: guest_hidden_delay_minutes) if guest_hidden_placeholder?

      redacted = cooked
      original = DiscourseGuestCommentDelay.text_from_html(super)
      redacted_text = DiscourseGuestCommentDelay.text_from_html(redacted)

      redacted_text == original ? super : redacted_text
    end

    def include_truncated?
      cooked.to_s.length > 300
    end

    private

    def guest_hidden_placeholder?
      DiscourseGuestCommentDelay.guest_hidden_post?(post: object, scope: scope)
    end

    def guest_hidden_delay_minutes
      DiscourseGuestCommentDelay.delay_minutes_for_post(post: object)
    end
  end
end
