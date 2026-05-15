# frozen_string_literal: true

module DiscourseGuestCommentDelay
  module SearchPostSerializerExtension
    def blurb
      if DiscourseGuestCommentDelay.guest_hidden_post?(post: object, scope: scope)
        return DiscourseGuestCommentDelay.placeholder_text(
          delay_minutes: DiscourseGuestCommentDelay.delay_minutes_for_post(post: object)
        )
      end

      return super unless object.respond_to?(:cooked)

      redacted = DiscourseGuestCommentDelay.redact_hidden_quotes_for_guest(
        cooked: object.cooked,
        post: object,
        scope: scope,
        text: true
      )
      original = DiscourseGuestCommentDelay.text_from_html(object.cooked)

      redacted == original ? super : redacted
    end
  end
end
