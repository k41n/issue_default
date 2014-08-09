# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

put '/issues/:id/escalate', action: :escalate, controller: :issues, as: :escalate

get '/tracker_settings/:project_id', action: :edit, controller: :tracker_settings, as: :edit_tracker_settings
post '/tracker_settings/:project_id', action: :update, controller: :tracker_settings, as: :update_tracker_settings

