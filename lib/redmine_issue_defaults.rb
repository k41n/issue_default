ActionDispatch::Reloader.to_prepare do
  require_dependency 'patches/issues_helper_patch'
  require_dependency 'patches/issues_controller_patch'
  require_dependency 'patches/issue_patch'
end

require 'hooks/view_layouts_hook'