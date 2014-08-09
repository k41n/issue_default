class AddDefaultAssigneeToProjectsTrackers < ActiveRecord::Migration
  def self.up
    add_column :projects_trackers, :default_assignee_id, :integer
    add_index :projects_trackers, :default_assignee_id
  end

  def self.down
    remove_index :projects_trackers, :default_assignee_id
    remove_column :projects_trackers, :default_assignee_id
  end
end