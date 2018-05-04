#
# Cookbook Name:: cdap
# Recipe:: sdk
#
# Copyright © 2015-2017 Cask Data, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Dependencies
%w(ark nodejs).each do |recipe|
  include_recipe recipe
end

include_recipe 'java' unless node['cdap'].key?('skip_prerequisites') && node['cdap']['skip_prerequisites'].to_s == 'true'

link '/usr/bin/node' do
  to '/usr/local/bin/node'
  action :create
  not_if 'test -e /usr/bin/node'
end

ver = node['cdap']['version'].gsub(/-.*/, '')
ark_prefix_path =
  if %W(sdk-#{ver} sandbox-#{ver}).include? ::File.basename(node['cdap']['sdk']['install_path'])
    ::File.dirname(node['cdap']['sdk']['install_path'])
  else
    node['cdap']['sdk']['install_path']
  end

directory ark_prefix_path do
  action :create
  recursive true
end

user node['cdap']['sdk']['user'] do
  comment "CDAP #{node['cdap']['sdk']['product_name'].upcase} Service Account"
  home node['cdap']['sdk']['install_path']
  shell '/bin/bash'
  system true
  action :create
  only_if { node['cdap']['sdk']['manage_user'].to_s == 'true' }
end

template "/etc/init.d/cdap-#{node['cdap']['sdk']['product_name']}" do
  source 'cdap-service.erb'
  mode '0755'
  owner 'root'
  group 'root'
  action :create
  variables node['cdap']['sdk']
  notifies :run, 'execute[systemd-daemon-reload]', :immediately
end

# COOK-98
template "/etc/profile.d/cdap-#{node['cdap']['sdk']['product_name']}.sh" do
  source 'generic-env.sh.erb'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
  variables options: node['cdap']['sdk']['profile_d']
end

ark 'sdk' do
  name node['cdap']['sdk']['product_name']
  url node['cdap']['sdk']['url']
  prefix_root ark_prefix_path
  prefix_home ark_prefix_path
  checksum node['cdap']['sdk']['checksum'] if node['cdap']['sdk']['enforce_checksum'].to_s == 'true'
  version ver
  owner node['cdap']['sdk']['user']
  group node['cdap']['sdk']['user']
  notifies :restart, "service[cdap-#{node['cdap']['sdk']['product_name']}]", :delayed if node['cdap']['sdk']['init_actions'].include?(:start)
end

execute 'systemd-daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
  only_if { node['init_package'] == 'systemd' }
end

service "cdap-#{node['cdap']['sdk']['product_name']}" do
  action node['cdap']['sdk']['init_actions']
end
