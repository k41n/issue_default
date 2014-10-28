module RedmineIssueDefaults
  module Patches

    module AccountControllerPatch
      def self.included(base) # :nodoc:
        Rails.logger.info "Account controller patch applied"
        puts "Account controller patch applied"
        base.class_eval do

          def successful_authentication(user)
            logger.info "Successful authentication for '#{user.login}' from #{request.remote_ip} at #{Time.now.utc}"
            # Valid user
            self.logged_user = user
            # generate a key and set cookie if autologin
            if params[:autologin] && Setting.autologin?
              set_autologin_cookie(user)
            end
            call_hook(:controller_account_success_authentication_after, {:user => user })
            if executor?
              Rails.logger.info "Special login redirect for executor to #{project_issues_url(Project.first)}"
              redirect_to project_issues_path(Project.first)
            else
              redirect_back_or_default my_page_path, :referer => true
            end
          end

          def login
            Rails.logger.info "login"
            if request.get?
              if User.current.logged?
                url = executor? ? issues_url(Project.first) : home_url
                Rails.logger.info "After login URL = #{url}"
                redirect_back_or_default url, :referer => true
              end
            else
              authenticate_user
            end
          rescue AuthSourceException => e
            logger.error "An error occured when authenticating #{params[:username]}: #{e.message}"
            render_error :message => e.message
          end

          def executor?
            User.current.roles_for_project(Project.first).map(&:name).include?('Исполнитель')
          end
        end
      end
    end
  end
end

unless AccountController.included_modules.include?(RedmineIssueDefaults::Patches::AccountControllerPatch)
  AccountController.send(:include, RedmineIssueDefaults::Patches::AccountControllerPatch)
end
