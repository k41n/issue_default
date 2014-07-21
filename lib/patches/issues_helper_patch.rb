require_dependency 'issues_helper'

module RedmineIssueDefaults
  module Patches

    module IssuesHelperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        # base.class_eval do
        #   alias_method_chain :custom_fields_tabs, :contacts_tab
        # end
      end

      module InstanceMethods
        def available_trackers(user, project)
          if user.roles_for_project(project).map(&:name).include? "Исполнитель"
            return [Tracker.find_by_name('Возврат покупки')]
          end
          if user.roles_for_project(project).map(&:name).include? "Инициатор"
            return project.trackers - [Tracker.find_by_name('Возврат покупки')]
          end
          project.trackers
        end
      end

    end

  end
end

unless IssuesHelper.included_modules.include?(RedmineIssueDefaults::Patches::IssuesHelperPatch)
  IssuesHelper.send(:include, RedmineIssueDefaults::Patches::IssuesHelperPatch)
end
