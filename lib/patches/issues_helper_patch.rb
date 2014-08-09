require_dependency 'issues_helper'

module RedmineIssueDefaults
  module Patches

    module IssuesHelperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

      end

      module InstanceMethods
        def available_trackers(project)
          if is_executor?(project)
            return [Tracker.find_by_name('Возврат покупки')]
          end
          if user.roles_for_project(project).map(&:name).include? "Инициатор"
            return project.trackers - [Tracker.find_by_name('Возврат покупки')]
          end
          project.trackers
        end

        def executor_editing?(issue)
          is_executor?(issue.project) && !issue.new_record?
        end

        def is_executor?(project)
          user.roles_for_project(project).map(&:name).include? "Исполнитель"
        end

        def user
          @user ||= User.current
        end

        def tracker_id_to_assignee_id
          j(Hash[ProjectsTracker.where(project_id: @project.id).map{ |x| [x.tracker_id, x.default_assignee_id] }].to_json)
        end
      end

    end

  end
end

unless IssuesHelper.included_modules.include?(RedmineIssueDefaults::Patches::IssuesHelperPatch)
  IssuesHelper.send(:include, RedmineIssueDefaults::Patches::IssuesHelperPatch)
end
