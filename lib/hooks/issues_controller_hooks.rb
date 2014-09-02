module RedmineIssueDefaults
  module Hooks
    class ControllerIssuesNewBeforeSaveHook < Redmine::Hook::ViewListener
      def controller_issues_new_before_save(context = {})
        issue = context[:issue]
        params = context[:params]
        if ['Отмена операции', 'Акты сверки'].include?(issue.tracker.name) && params[:attachments].blank?
          issue.attachment_error = 'Так дело не пойдет, надо приложить файл'
        end
      end
    end
  end
end