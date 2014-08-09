class TrackerSettingsController < ApplicationController
  before_filter :find_project

  def edit
    @trackers = @project.trackers
    @assignable = @project.assignable_users
  end

  def update
    params[:default_assignee].each do |k,v|
      projects_tracker = ProjectsTracker.where(project_id: @project.id, tracker_id: k.to_i)
      projects_tracker.update_all(default_assignee_id: v.to_i)
    end
    redirect_to edit_tracker_settings_path(@project)
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  end
end