module RedmineIssueDefaults
  module Patches

    module QueryPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method_chain :statement, :sber
        end
      end
    end

    module InstanceMethods
      def statement_with_sber
        # filters clauses
        filters_clauses = []
        filters.each_key do |field|
          next if field == "subproject_id"
          v = values_for(field).clone
          next unless v and !v.empty?
          operator = operator_for(field)

          # "me" value subsitution
          if %w(assigned_to_id author_id user_id watcher_id).include?(field)
            if v.delete("me")
              if User.current.logged?
                v.push(User.current.id.to_s)
                v += User.current.group_ids.map(&:to_s) if field == 'assigned_to_id'
              else
                v.push("0")
              end
            end
          end

          if field == 'project_id'
            if v.delete('mine')
              v += User.current.memberships.map(&:project_id).map(&:to_s)
            end
          end

          if field =~ /cf_(\d+)$/
            # custom field
            filters_clauses << sql_for_custom_field(field, operator, v, $1)
          elsif respond_to?("sql_for_#{field}_field")
            # specific statement
            filters_clauses << send("sql_for_#{field}_field", field, operator, v)
          else
            # regular field
            filters_clauses << '(' + sql_for_field(field, operator, v, queried_table_name, field) + ')'
          end
        end if filters and valid?

        if (c = group_by_column) && c.is_a?(QueryCustomFieldColumn)
          # Excludes results for which the grouped custom field is not visible
          filters_clauses << c.custom_field.visibility_by_project_condition
        end

        filters_clauses << project_statement
        filters_clauses.reject!(&:blank?)

        user = User.current
        filters_clauses << "((issues.author_id='#{user.id}') OR (issues.assigned_to_id='#{user.id}'))" if user && user.roles_for_project(project).map(&:name).include?("Инициатор")

        filters_clauses.any? ? filters_clauses.join(' AND ') : nil

      end
    end

  end
end

unless Query.included_modules.include?(RedmineIssueDefaults::Patches::QueryPatch)
  Query.send(:include, RedmineIssueDefaults::Patches::QueryPatch)
end
