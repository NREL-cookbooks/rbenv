#
# Cookbook Name:: rbenv
# Recipe:: system
#
# Copyright 2010, 2011 Fletcher Nichol
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "rbenv::system_install"

Array(node['rbenv']['rubies']).each do |rubie|
  if rubie.is_a?(Hash)
    # Ensure java gets installed prior to JRuby.
    if rubie['name'] =~ /^jruby-/
      include_recipe "java"
    end

    rbenv_ruby rubie['name'] do
      environment rubie['environment'] if rubie['environment']
    end
  else
    # Ensure java gets installed prior to JRuby.
    if rubie =~ /^jruby-/
      include_recipe "java"
    end

    rbenv_ruby rubie
  end
end

if node['rbenv']['global']
  rbenv_global node['rbenv']['global'] do
    notifies :create, "ruby_block[create_predictable_gem_symlink]", :immediately
  end

  # Force set ruby ohai attributes.
  #
  # This is done before new global version of ruby is actually installed so
  # that other cookbooks can easily reference the to-be-installed version. This
  # is done to prevent the first chef run from incorrectly using the previous
  # version of ruby when a new version of ruby is being installed.
  #
  # This is done at compile time, rather than just reloading the ohai
  # attributes at convergence time, to deal with recipes like nginx's passenger
  # that heavily use these path attributes in defining other attributes and
  # resources at compile time.
  node.automatic_attrs[:languages][:ruby][:bin_dir] = "#{node[:rbenv][:root_path]}/versions/#{node[:rbenv][:global]}/bin"
  node.automatic_attrs[:languages][:ruby][:gem_bin] = "#{node[:rbenv][:root_path]}/versions/#{node[:rbenv][:global]}/bin/gem"
  node.automatic_attrs[:languages][:ruby][:gems_dir] = "#{node[:rbenv][:root_path]}/versions/#{node[:rbenv][:global]}/gems"
  node.automatic_attrs[:languages][:ruby][:ruby_bin] = "#{node[:rbenv][:root_path]}/versions/#{node[:rbenv][:global]}/bin/ruby"

  # Create a symlink to the real gem directory.
  #
  # This is used by the automatic_attrs above. This is necessary so that at
  # compile time we have a predictable path where the gems will be installed
  # (because the version number in the real directory like
  # lib/ruby/gems/VERSION is hard to predict ahead of time).
  predictable_gem_symlink = "#{node[:rbenv][:root_path]}/versions/#{node[:rbenv][:global]}/gems"
  ruby_block "create_predictable_gem_symlink" do
    block do
      real_gem_dir = `/bin/bash -c "source /etc/profile.d/rbenv.sh && rbenv shell #{node['rbenv']['global']} && gem env gemdir"`.strip
      ::FileUtils.ln_s(real_gem_dir, predictable_gem_symlink)
    end

    only_if do
      ::File.exists?("#{node[:rbenv][:root_path]}/versions/#{node[:rbenv][:global]}") && !::File.exists?(predictable_gem_symlink)
    end
  end

  # Configure the gemrc file to not install rdoc and ri for everyone
  if node['rbenv']['no_rdoc_ri']
    template "/etc/gemrc" do
      source  "gemrc.erb"
      owner   "root"
      mode    "0755"
      #only_if {node['rbenv']['gems'].size > 0}
    end
  end
end



node['rbenv']['gems'].each_pair do |rubie, gems|
  Array(gems).each do |gem|
    rbenv_gem gem['name'] do
      rbenv_version rubie

      %w{version action options source}.each do |attr|
        send(attr, gem[attr]) if gem[attr]
      end
    end
  end
end
