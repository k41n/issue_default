module RedmineIssueDefaults
  module Patches
    module IssueQueryPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method_chain :initialize_available_filters, :sber
        end
      end
    end

    module InstanceMethods
      def initialize_available_filters_with_sber
        initialize_available_filters_without_sber
        @available_filters.delete_if do |k, v|
          not %w(tracker_id status_id author_id).include?(k.to_s)
        end
      end
    end
  end
end

unless IssueQuery.included_modules.include?(RedmineIssueDefaults::Patches::IssueQueryPatch)
  IssueQuery.send(:include, RedmineIssueDefaults::Patches::IssueQueryPatch)
end
