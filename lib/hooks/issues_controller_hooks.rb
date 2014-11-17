module RedmineIssueDefaults
  module Hooks
    class ControllerIssuesNewBeforeSaveHook < Redmine::Hook::ViewListener
      def controller_issues_new_before_save(context = {})
        issue = context[:issue]
        params = context[:params]
        if ['Отмена операции', 'Акты сверки', 'Процессирование операции'].include?(issue.tracker.name) && params[:attachments].blank?
          unless issue.tracker.name == 'Акты сверки' && params[:issue][:corellation_act_type] == '1'
            issue.attachment_error = 'Так дело не пойдет, надо приложить файл'
          end
        end
        if issue.tracker.name == 'Розыск платежа' && ['Розыск по транзакции', 'Розыск неопознанной суммы'].include?(params[:issue][:custom_field_values].try(:[],'34')) && params[:attachments].blank?
          issue.attachment_error = 'Так дело не пойдет, надо приложить файл'
        end
      end
    end

    class ControllerIssuesEditBeforeSaveHook < Redmine::Hook::ViewListener
      def controller_issues_edit_before_save(context = {})
        issue = context[:issue]
        params = context[:params]
        if ['Акты сверки', 'Розыск платежа', 'Отмена операции', 'Процессирование операции'].include?(issue.tracker.name) &&
          params[:attachments].blank? &&
          params[:issue][:notes].blank? &&
          issue.status.name == 'Ответ подготовлен'

          issue.attachment_error = 'Нужно оставить комментарий или приложить файл'
        end
      end
    end
  end
end