include_recipe "rbenv::system_install"
include_recipe "rbenv::ohai_plugin"

rbenv_ruby(node[:rbenv][:install_global_version]) do
  global true
  notifies :reload, "ohai[custom_plugins]", :immediately
end

node.automatic_attrs[:languages][:ruby][:ruby_bin] = "#{node[:rbenv][:install_prefix]}/rbenv/shims/ruby"
node.automatic_attrs[:languages][:ruby][:gems_dir] = "#{node[:rbenv][:install_prefix]}/rbenv/versions/#{node[:rbenv][:install_global_version]}/gems"

include_recipe "rubygems::client"
