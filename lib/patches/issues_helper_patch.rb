require_dependency 'issues_helper'

module RedmineIssueDefaults
  module Patches

    module IssuesHelperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

      end

      module InstanceMethods
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

        def render_custom_fields_rows(issue)
          values = issue.visible_custom_field_values
          return if values.empty?
          ordered_values = []
          half = (values.size / 2.0).ceil
          half.times do |i|
            ordered_values << values[i]
            ordered_values << values[i + half]
          end
          s = "<tr>\n"
          n = 0
          number_of_13th_value = 0
          ordered_values.compact.each do |value|
            if value.custom_field && value.custom_field.id == 13
              number_of_13th_value = n
            end
            if n == number_of_13th_value + 2 && n > 0 && issue.corellation_act_type
              s << "</tr>\n<tr>\n" if n > 0 && (n % 2) == 0
              s << "\t<th>Подтип запроса:</th><td>#{t(:corellation_act_types)[issue.corellation_act_type]}</td>\n"
              n += 1
            end
            css = "cf_#{value.custom_field.id}"
            s << "</tr>\n<tr>\n" if n > 0 && (n % 2) == 0
            s << "\t<th class=\"#{css}\">#{ h(value.custom_field.name) }:</th><td class=\"#{css}\">#{ h(show_value(value)) }</td>\n"
            n += 1
          end
          s << "</tr>\n"
          s.html_safe
        end
        
      end

    end

  end
end

unless IssuesHelper.included_modules.include?(RedmineIssueDefaults::Patches::IssuesHelperPatch)
  IssuesHelper.send(:include, RedmineIssueDefaults::Patches::IssuesHelperPatch)
end
