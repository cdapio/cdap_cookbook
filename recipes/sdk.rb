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
%w(ark java nodejs).each do |recipe|
  include_recipe recipe
end

link '/usr/bin/node' do
  to '/usr/local/bin/node'
  action :create
  not_if 'test -e /usr/bin/node'
end

repo = node['cdap']['source']['git']['repo']['cdap-build']

if node['cdap']['install_method'] == 'source' && !repo['branch'].nil? && !repo['branch'].empty?
  if node['cdap']['source']['skip_build'].to_s == 'true'
    log 'cdap-ambari-service-skip-build' do
      message 'CDAP: Skipping build of cdap-ambari-service from source due to skip_build == true'
    end
  else
    # Setting up Maven command for SDK build
    ver = node['cdap']['version'].to_f
    profiles = %w(dist examples)
    profiles += %w(templates unit-tests) if ver >= 3.0
    mvn_extra_opts = node['cdap']['source']['maven_extra_opts']
    mvn_command = "mvn package -DskipTests -B -P #{profiles.join(',')} -U -V #{mvn_extra_opts}"
    mvn_command += " -Dadditional.artifacts.dir=#{repo['dir']}/app-artifacts" if ver >= 3.3
    mvn_command += " -Dsecurity.extensions.dir=#{repo['dir']}/security-extensions" if ver >= 3.5

    # Modify the Maven command in the _maven recipe to build the SDK only
    ruby_block 'modify-cdap-maven-resource' do
      block do
        begin
          r = resources(bash: 'maven-build-cdap-packages')
          r.command(mvn_command)
        rescue Chef::Exceptions::ResourceNotFound
          Chef::Log.fatal('Resource maven-build-cdap-packages not found... SDK will not build correctly')
        end
      end
    end

    # Modify the 'cdap' package resource in default recipe to do nothing
    ruby_block 'modify-cdap-package-resource' do
      block do
        begin
          r = resources(package: 'cdap')
          r.action(:nothing)
        rescue Chef::Exceptions::ResourceNotFound
          Chef::Log.debug('Resource not found for package[cdap]... this is fine')
        end
      end
    end

    include_recipe 'cdap::_maven'

    # This block updates the SDK ark resource
    # - sets url attribute to a 'file:///path/to/local/sdk
    # - sets version to a version parsed from sdk filename
    #
    ruby_block 'modify-cdap-sdk-ark-resources' do # ~FC014
      block do
        ::Dir["#{repo['dir']}/cdap/cdap-standalone/target/cdap-sdk*.zip"].each do |f|
          begin
            r = resources(ark: 'sdk')

            # Set the url to the location of the built SDK.  Note, this also causes the checksum attr to be ignored
            sdk_url = "file://#{f}"
            Chef::Log.info("Modifying ark url for SDK to #{sdk_url}")
            r.url(sdk_url)

            # Set the version to the version of the built SDK
            sdk_version = f.gsub(/.*cdap-sdk-(.*).zip/, '\1')
            Chef::Log.info("Modifying ark version for SDK to #{sdk_version}")
            r.version(sdk_version)

            # Calculate and set the expected checksum
            r.checksum(Digest::SHA256.hexdigest(File.read(f)))

          rescue Chef::Exceptions::ResourceNotFound
            Chef::Log.warn('No resource ark:sdk found in the resources collection... skipping')
          end
        end
      end
    end
  end
end

ver = node['cdap']['version'].gsub(/-.*/, '')
ark_prefix_path = ::File.dirname(node['cdap']['sdk']['install_path']) if ::File.basename(node['cdap']['sdk']['install_path']) == "sdk-#{ver}"
ark_prefix_path ||= node['cdap']['sdk']['install_path']

directory ark_prefix_path do
  action :create
  recursive true
end

user node['cdap']['sdk']['user'] do
  comment 'CDAP SDK Service Account'
  home node['cdap']['sdk']['install_path']
  shell '/bin/bash'
  system true
  action :create
  only_if { node['cdap']['sdk']['manage_user'].to_s == 'true' }
end

template '/etc/init.d/cdap-sdk' do
  source 'cdap-service.erb'
  mode '0755'
  owner 'root'
  group 'root'
  action :create
  variables node['cdap']['sdk']
end

# COOK-98
template '/etc/profile.d/cdap-sdk.sh' do
  source 'generic-env.sh.erb'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
  variables :options => { 'path' => "${PATH}:#{node['cdap']['sdk']['install_path']}/sdk/bin" }
end

ark 'sdk' do
  url node['cdap']['sdk']['url']
  prefix_root ark_prefix_path
  prefix_home ark_prefix_path
  checksum node['cdap']['sdk']['checksum']
  version ver
  owner node['cdap']['sdk']['user']
  group node['cdap']['sdk']['user']
  notifies :restart, 'service[cdap-sdk]', :delayed if node['cdap']['sdk']['init_actions'].include?(:start)
end

service 'cdap-sdk' do
  action node['cdap']['sdk']['init_actions']
end
