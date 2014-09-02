module RedmineIssueDefaults
  module Patches

    module IssuePatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          safe_attributes :corellation_act_type

          alias_method_chain :create_journal, :sber

          validate :check_attachment_error, on: :create
          attr_accessor :attachment_error
        end
      end
    end

    module InstanceMethods
      def check_attachment_error
        errors[:base] << @attachment_error if @attachment_error
      end

      def create_journal_with_sber
        if @current_journal
          # attributes changes
          if @attributes_before_change
            %w(status_id).each {|c|
              before = @attributes_before_change[c]
              after = send(c)
              next if before == after || (before.blank? && after.blank?)
              @current_journal.details << JournalDetail.new(:property => 'attr',
                                                            :prop_key => c,
                                                            :old_value => before,
                                                            :value => after)
            }
          end
          @current_journal.save
          # reset current journal
          init_journal @current_journal.user, @current_journal.notes
        end
      end
    end

  end
end

unless Issue.included_modules.include?(RedmineIssueDefaults::Patches::IssuePatch)
  Issue.send(:include, RedmineIssueDefaults::Patches::IssuePatch)
end
