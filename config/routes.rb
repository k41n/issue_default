# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

put '/issues/:id/escalate', action: :escalate, controller: :issues, as: :escalate
