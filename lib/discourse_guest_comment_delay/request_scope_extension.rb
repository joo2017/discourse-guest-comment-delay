# frozen_string_literal: true

module DiscourseGuestCommentDelay
  module RequestScopeExtension
    def process_action(*args)
      DiscourseGuestCommentDelay.with_request_scope(current_user) { super }
    end
  end
end
