#
# Cookbook Name:: cdap
# Recipe:: config
#
# Copyright © 2013-2017 Cask Data, Inc.
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

cdap_conf_dir = "/etc/cdap/#{node['cdap']['conf_dir']}"

directory cdap_conf_dir do
  mode '0755'
  owner 'root'
  group 'root'
  action :create
  recursive true
end

# Evaluate any Delayed Interpolation tokens
Chef::Recipe.send(:include, Hadoop::Helpers)
delayed_attrs = { _FULL_VERSION: hdp_version }

# Setup cdap-site.xml cdap-security.xml
%w(cdap_site cdap_security).each do |sitefile|
  next unless node['cdap'].key?(sitefile)

  # Evaluate any Delayed Interpolation tokens in cdap-site attributes
  if node['cdap'].key?(sitefile) && !node['cdap'][sitefile].empty?
    node['cdap'][sitefile].each do |k, v|
      node.default['cdap'][sitefile][k] = v % delayed_attrs
    end
  end

  template "#{cdap_conf_dir}/#{sitefile.tr('_', '-')}.xml" do
    source 'generic-site.xml.erb'
    mode sitefile == 'cdap_security' ? '0600' : '0644'
    owner 'cdap'
    group 'cdap'
    variables options: node['cdap'][sitefile]
    action :create
  end
end # End cdap-site.xml cdap-security.xml

# Evaluate any Delayed Interpolation tokens in cdap-env attributes
if node['cdap'].key?('cdap_env') && !node['cdap']['cdap_env'].empty?
  node['cdap']['cdap_env'].each do |k, v|
    node.default['cdap']['cdap_env'][k] = v % delayed_attrs
  end
end

# Setup cdap-env.sh
template "#{cdap_conf_dir}/cdap-env.sh" do
  source 'generic-env.sh.erb'
  mode '0644'
  owner 'cdap'
  group 'cdap'
  variables options: node['cdap']['cdap_env']
  action :create
  only_if { node['cdap'].key?('cdap_env') }
end # End cdap-env.sh

execute 'copy logback.xml from conf.dist' do
  command "cp -f /etc/cdap/conf.dist/logback.xml /etc/cdap/#{node['cdap']['conf_dir']}"
  not_if { ::File.exist?("/etc/cdap/#{node['cdap']['conf_dir']}/logback.xml") }
end

execute 'copy logback-container.xml from conf.dist' do
  command "cp /etc/cdap/conf.dist/logback-container.xml /etc/cdap/#{node['cdap']['conf_dir']}"
  not_if { ::File.exist?("/etc/cdap/#{node['cdap']['conf_dir']}/logback-container.xml") }
end

# Update alternatives to point to our configuration
execute 'update cdap-conf alternatives' do
  command "update-alternatives --install /etc/cdap/conf cdap-conf /etc/cdap/#{node['cdap']['conf_dir']} 50"
  not_if "update-alternatives --display cdap-conf | grep best | awk '{print $5}' | grep /etc/cdap/#{node['cdap']['conf_dir']}"
end
