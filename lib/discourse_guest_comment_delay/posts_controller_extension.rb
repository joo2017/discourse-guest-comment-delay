# frozen_string_literal: true

module DiscourseGuestCommentDelay
  module PostsControllerExtension
    def index
      super

      return unless request.format.rss?
      return unless instance_variable_defined?(:@posts)

      @posts = DiscourseGuestCommentDelay.decorate_hidden_posts_for_guest(instance_variable_get(:@posts), user: current_user)
    end
  end
end
