class AddExecutedOnFieldToIssue < ActiveRecord::Migration
  def self.up
    add_column :issues, :executed_on, :datetime
  end

  def self.down
    remove_column :issues, :executed_on
  end
end