include_recipe "rbenv::system_install"
include_recipe "rbenv::ohai_plugin"

rbenv_ruby(node[:rbenv][:install_global_version]) do
  global true
  notifies :reload, "ohai[custom_plugins]", :immediately
end

include_recipe "rubygems::client"
