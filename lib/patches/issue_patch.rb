module RedmineIssueDefaults
  module Patches

    module IssuePatch
      def self.included(base) # :nodoc:
        base.class_eval do
          safe_attributes :corellation_act_type
        end
      end
    end
  end
end

unless Issue.included_modules.include?(RedmineIssueDefaults::Patches::IssuePatch)
  Issue.send(:include, RedmineIssueDefaults::Patches::IssuePatch)
end
