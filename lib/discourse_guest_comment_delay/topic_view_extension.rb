# frozen_string_literal: true

module DiscourseGuestCommentDelay
  module TopicViewExtension
    def crawler_posts
      DiscourseGuestCommentDelay.decorate_hidden_posts_for_guest(super, user: @user)
    end

    def recent_posts
      DiscourseGuestCommentDelay.decorate_hidden_posts_for_guest(super, user: @user)
    end

    def summary(opts = {})
      return DiscourseGuestCommentDelay.placeholder_text(delay_minutes: DiscourseGuestCommentDelay.delay_minutes_for_post(post: desired_post)) if desired_post && DiscourseGuestCommentDelay.guest_hidden_post_for_user?(post: desired_post, user: @user)

      super
    end
  end
end
