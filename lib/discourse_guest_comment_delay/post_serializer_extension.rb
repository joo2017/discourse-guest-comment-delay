# frozen_string_literal: true

module DiscourseGuestCommentDelay
  module PostSerializerExtension
    module Shared
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

      def cooked
        return DiscourseGuestCommentDelay.placeholder_html(delay_minutes: guest_hidden_delay_minutes) if guest_hidden_placeholder?

        super
      end

      def raw
        return DiscourseGuestCommentDelay.placeholder_text(delay_minutes: guest_hidden_delay_minutes) if guest_hidden_placeholder?

        super
      end

      def cooked_hidden
        return false if guest_hidden_placeholder?

        super
      end
    end

    module Post
      include Shared
    end
  end
end
