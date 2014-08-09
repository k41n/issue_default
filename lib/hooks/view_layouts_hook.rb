module RedmineIssueDefaults
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context={})
        return stylesheet_link_tag(:sber, :plugin => 'issue_defaults')
      end
    end
  end
end