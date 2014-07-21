module RedmineIssueDefaults
  module Patches

    module IssuesControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          skip_before_filter :authorize, only: :escalate
        end

      end

      module InstanceMethods
        def escalate
          find_issue
          head 403 && return unless User.current.roles_for_project(@issue.project).map(&:name).include?('Инициатор')
          User.find_each do |user|
            if user.roles_for_project(@issue.project).map(&:name).include?('Эскалатор')
              Watcher.create(:watchable => @issue, :user_id => user.id)
            end
          end
          redirect_to issue_path(@issue)
        end
      end

    end

  end
end

unless IssuesController.included_modules.include?(RedmineIssueDefaults::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineIssueDefaults::Patches::IssuesControllerPatch)
end
