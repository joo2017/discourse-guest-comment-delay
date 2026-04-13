# frozen_string_literal: true

# name: discourse-guest-comment-delay
# about: Hide recent replies from anonymous users until a configured delay expires.
# version: 0.1.0
# authors: OpenAI
# url: https://github.com/discourse/discourse

require_relative "lib/discourse_guest_comment_delay"

register_asset "stylesheets/common/guest-comment-delay.scss" if respond_to?(:register_asset)

after_initialize do
  DiscourseGuestCommentDelay.register!(self)

  on(:reduce_cooked) do |fragment, post|
    DiscourseGuestCommentDelay.reduce_cooked_fragment_for_guest!(fragment: fragment, post: post)
  end
end if respond_to?(:after_initialize)
