module RedmineIssueDefaults
  module Patches

    module IssuesControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          skip_before_filter :authorize, only: :escalate
          alias_method_chain :index, :defaults

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
            params[:set_filter] = "1"
            params[:f] = ["assigned_to_id", "author_id", ""]
            params[:op] = {"assigned_to_id"=>"=", "author_id"=>"="}
            params[:v] = {"assigned_to_id"=>["me"], "author_id"=>["me"]}            
          end
          index_without_defaults
        end
      end

    end

  end
end

unless IssuesController.included_modules.include?(RedmineIssueDefaults::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineIssueDefaults::Patches::IssuesControllerPatch)
end
