#
# Cookbook Name:: rbenv
# Recipe:: default
#
# Copyright 2011, Fletcher Nichol
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

# Always install build-essentials. A plain jruby install seems to even require
# this (or else installing bombs out when installing jruby-launcher). Also, C
# extensions typically requires this, so we might as well go ahead and install.
include_recipe "build-essential"

# Make sure the ruby_build cookbook gets loaded before rbenv so it's availible
# and up to date.
if node.recipe?('ruby_build')
  include_recipe 'ruby_build'
end

class Chef::Recipe
  # mix in recipe helpers
  include Chef::Rbenv::RecipeHelpers
end
