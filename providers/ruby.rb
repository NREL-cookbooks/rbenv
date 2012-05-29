#
# Cookbook Name:: rbenv
# Provider:: ruby
#
# Author:: Jamie Winsor (<jamie@vialstudios.com>)
#
# Copyright 2011-2012, Riot Games
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

include Chef::Mixin::Rbenv

action :install do
  if !@ruby.force && ruby_version_installed?(@ruby.name)
    Chef::Log.debug "rbenv_ruby[#{@ruby.name}] is already installed so skipping"
  else
    Chef::Log.info "rbenv_ruby[#{@ruby.name}] is building, this may take a while..."

    start_time = Time.now

    out = rbenv_command("install #{@ruby.name}")

    unless out.exitstatus == 0
      raise Chef::Exceptions::ShellCommandFailed, "\n" + out.format_for_exception
    end

    Chef::Log.debug("rbenv_ruby[#{@ruby.name}] build time was #{(Time.now - start_time)/60.0} minutes.")

    new_resource.updated_by_last_action(true)
  end

  if new_resource.global && !rbenv_global_version?(@ruby.name)
    Chef::Log.info "Setting #{@ruby.name} as the rbenv global version"
    out = rbenv_command("global #{@ruby.name}")
    unless out.exitstatus == 0
      raise Chef::Exceptions::ShellCommandFailed, "\n" + out.format_for_exception
    end
    new_resource.updated_by_last_action(true)
  end

  # Create a symlink to the real gem directory. This is done so that at compile
  # time we have a predictable path where the gems will be installed (instead
  # of having to wait until convergence which means wrapping everything inside
  # ruby_block statements).
  predictable_gem_dir = "#{node[:rbenv][:install_prefix]}/rbenv/versions/#{@ruby.name}/gems"
  unless(::File.exists?(predictable_gem_dir))
    real_gem_dir = `rbenv exec gem env gemdir`.strip
    ::FileUtils.ln_s(real_gem_dir, predictable_gem_dir) 
    new_resource.updated_by_last_action(true)
  end
end

def load_current_resource
  @ruby = Chef::Resource::RbenvRuby.new(new_resource.name)
end
