class AddCorellationActTypesToIssue < ActiveRecord::Migration
  def self.up
    add_column :issues, :corellation_act_type, :integer
  end

  def self.down
    remove_column :issues, :corellation_act_type
  end
end