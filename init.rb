Redmine::Plugin.register :issue_defaults do
  name 'Issue Defaults plugin'
  author 'LLC Kodep'
  description 'Customization in accordance to Stas Malyshev requirements'
  version '1.0.0'
  url 'https://github.com/k41n/issue_default'
  author_url 'Andrei.Malyshev@kodep.ru'
  
  permission :issue_defaults, { :tracker_settings => [:edit, :update] }
  menu :project_menu, :issue_defaults, { controller: :tracker_settings, action: :edit }, caption: 'Настройки типов запроса', param: :project_id, after: :activity
end

require 'redmine_issue_defaults'