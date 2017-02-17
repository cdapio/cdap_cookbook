#
# Cookbook Name:: cdap
# Recipe:: _git
#
# Copyright © 2015-2017 Cask Data, Inc.
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

# Install git from source to ensure we're new enough on RHEL6
include_recipe 'git::source'

# User to clone repos as
local_user =
  if node['cdap']['source']['git']['local_user'] == 'admin'
    'root'
  else
    node['cdap']['source']['git']['local_user']
  end
local_group = node['cdap']['source']['git']['local_group']

# Clone any repositories with a branch specified and sync = true
node['cdap']['source']['git']['repo'].each do |_repo, props|
  # Create parent directories unconditionally
  directory ::File.dirname(props['dir']) do
    action :create
    recursive true
    owner 'root'
    group 'root'
    mode '1777'
  end

  next if props['branch'].nil? || props['branch'].empty? || node['cdap']['source']['skip_sync'].to_s == 'true'

  git props['dir'] do # ~FC022
    action :sync
    revision props['branch']
    repository props['uri']
    enable_submodules true
    user local_user
    group local_group
    depth props['depth'] unless props['depth'].to_s.empty?
    only_if { props['sync'].to_s == 'true' }
    notifies :write, 'log[git-notifier-autobuild]', :delayed
  end

  # Loop through any submodules, if defined
  # - if branch.empty? update --remote; else checkout branch
  submodules = props['submodules'] || []
  submodules.each do |n, v|
    # We use a bash block to ensure we use the correct git binary and options
    bash "Run git submodule update --init --recursive --remote #{n}" do
      action :run
      code "/usr/local/bin/git submodule update --init --recursive --remote #{n}"
      user local_user
      group local_group
      only_if { (v['branch'].empty? || v['branch'].nil?) && v['sync'].to_s == 'true' }
      cwd props['dir']
      notifies :write, 'log[git-notifier-autobuild]', :delayed
    end
    # Run an update in the submodule to whatever branch the user's specified
    bash "Run git checkout #{v['branch']} in #{n}" do
      action :run
      code "/usr/local/bin/git checkout #{v['branch']}"
      user local_user
      group local_group
      not_if { v['branch'].empty? || v['branch'].nil? }
      only_if { v['sync'].to_s == 'true' }
      cwd "#{props['dir']}/#{n}"
      notifies :write, 'log[git-notifier-autobuild]', :delayed
    end
  end # End submodules
end

log 'git-notifier-autobuild' do
  message 'CDAP: One or more Git repositories was updated...'
  level :info
  action :nothing
end
