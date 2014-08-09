module RedmineIssueDefaults
  module Patches

    module IssuesControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          skip_before_filter :authorize, only: :escalate
          alias_method_chain :index, :defaults
          alias_method_chain :build_new_issue_from_params, :defaults
          helper_method :available_trackers

        end
      end

      module InstanceMethods
        def escalate
          find_issue
          update
          head 403 && return unless User.current.roles_for_project(@issue.project).map(&:name).include?('Инициатор')
          Rails.logger.info "-------- ESCALATION !!! ------------"
          User.find_each do |user|
            if user.roles_for_project(@issue.project).map(&:name).include?('Эскалатор')
              Watcher.create(:watchable => @issue, :user_id => user.id)
            end
          end
          # redirect_to issue_path(@issue)
        end

        def index_with_defaults
          if params[:set_filter] != '1'
            if initiator?
              params[:set_filter] = "1"
              params[:f] = ["author_id", ""]
              params[:op] = {"author_id"=>"="}
              params[:v] = {"author_id"=>["me"]}
            end

            if executor?
              params[:set_filter] = "1"
              params[:f] = ["assigned_to_id", ""]
              params[:op] = {"assigned_to_id"=>"="}
              params[:v] = {"assigned_to_id"=>["me"]}
            end
          end
          index_without_defaults
        end

        def build_new_issue_from_params_with_defaults
          build_new_issue_from_params_without_defaults
          @issue.tracker = available_trackers(@project).first if @issue.new_record?
        end

        def initiator?
          User.current.roles_for_project(@project).map(&:name).include?('Инициатор')
        end

        def executor?
          User.current.roles_for_project(@project).map(&:name).include?('Исполнитель')
        end

        def available_trackers(project)
          if is_executor?(project)
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

unless IssuesController.included_modules.include?(RedmineIssueDefaults::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineIssueDefaults::Patches::IssuesControllerPatch)
end
