# frozen_string_literal: true

module DiscourseGuestCommentDelay
  module PostSerializerExtension
    module Shared
      def cooked
        return DiscourseGuestCommentDelay.placeholder_html(delay_minutes: guest_hidden_delay_minutes) if guest_hidden_placeholder?

        DiscourseGuestCommentDelay.redact_hidden_quotes_for_guest(cooked: super, post: object, scope: scope)
      end

      def raw
        return DiscourseGuestCommentDelay.placeholder_text(delay_minutes: guest_hidden_delay_minutes) if guest_hidden_placeholder?

        super
      end

      def excerpt(*args)
        return DiscourseGuestCommentDelay.placeholder_text(delay_minutes: guest_hidden_delay_minutes) if guest_hidden_placeholder?

        return super unless object.respond_to?(:cooked)

        redacted = DiscourseGuestCommentDelay.redact_hidden_quotes_for_guest(
          cooked: object.cooked,
          post: object,
          scope: scope,
          text: true
        )
        original = object.respond_to?(:excerpt) ? object.excerpt(*args) : nil
        redacted == DiscourseGuestCommentDelay.text_from_html(object.cooked) ? super : redacted
      end

      def cooked_hidden
        return false if guest_hidden_placeholder?

        super
      end

      private

      def guest_hidden_placeholder?
        DiscourseGuestCommentDelay.guest_hidden_post?(post: object, scope: scope)
      end

      def guest_hidden_delay_minutes
        DiscourseGuestCommentDelay.delay_minutes_for_post(post: object)
      end
    end

    module Basic
      include Shared
    end

    module Post
      include Shared
    end
  end
end
