#
# Cookbook Name:: cdap
# Recipe:: ambari
#
# Copyright © 2016-2017 Cask Data, Inc.
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

include_recipe 'ambari::server' if node['cdap']['ambari']['install_ambari'].to_s == 'true'

repo = node['cdap']['source']['git']['repo']['cdap-ambari-service']
local_user =
  if node['cdap']['source']['git']['local_user'] == 'admin'
    'root'
  else
    node['cdap']['source']['git']['local_user']
  end
local_group = node['cdap']['source']['git']['local_group']

if node['cdap']['install_method'] == 'source' && !repo['branch'].nil? && !repo['branch'].empty?
  if node['cdap']['source']['skip_build'].to_s == 'true'
    log 'cdap-ambari-service-skip-build' do
      message 'CDAP: Skipping build of cdap-ambari-service from source due to skip_build == true'
    end
  else
    include_recipe 'cdap::_fpm'
    include_recipe 'cdap::_git'
    package_formats =
      if node['platform_family'] == 'debian'
        'deb'
      elsif node['platform_family'] == 'rhel'
        'rpm'
      end
    run_action =
      if node['cdap']['source']['force_build']
        :run
      else
        :nothing
      end
    # Run the build.sh script when git resource changes or otherwise notified
    bash 'build-cdap-ambari-service-package' do
      action run_action
      code <<-EOH
        set -o pipefail
        ./build.sh | tee -a /var/log/cdap-ambari-service-autobuild.log
        ret=$?
        if [[ ${ret} -ne 0 ]]; then
          rm -rf #{repo['dir']}/var
        fi
        exit ${ret}
      EOH
      cwd repo['dir']
      user local_user
      group local_group
      environment('PACKAGE_FORMATS' => package_formats,
                  'PATH' => "/opt/chef/embedded/bin:#{ENV['PATH']}")
      subscribes :run, "git[#{repo['dir']}]", :immediately unless node['cdap']['source']['force_build'].to_s == 'true'
    end
    # Emperically we have seen the initial git clone not generate a notification. This is a workaround
    log 'build-cdap-ambari-service-trigger' do
      message 'Triggering build for cdap-ambari-service since var is not present'
      notifies :run, 'bash[build-cdap-ambari-service-package]', :immediately
      not_if "test -d #{repo['dir']}/var"
    end
  end

  # This block updates the package resource from the cdap cookbook.
  # - identifies each package in the cdap-ambari-service repo
  # - adds source attribute to package's resource
  #
  # Example: cdap-ambari-service_3.4.0-1_all.deb adds source to package[cdap-ambari-service] resource
  ruby_block 'modify-cdap-ambari-service-package-resources' do # ~FC014
    block do
      pkg_files =
        if node['platform_family'] == 'debian'
          ::Dir["#{repo['dir']}/cdap*.deb"]
        elsif node['platform_family'] == 'rhel'
          ::Dir["#{repo['dir']}/cdap*.rpm"]
        else
          []
        end

      pkg_files.each do |f|
        p = f.split('/')[-2]
        begin
          r = resources(package: p)
          r.source(f)
          r.provider(Chef::Provider::Package::Dpkg) if node['platform_family'] == 'debian'
        rescue Chef::Exceptions::ResourceNotFound
          Chef::Log.warn("No package[#{p}] found in the resources collection... skipping")
        end
      end
    end
  end
else
  include_recipe 'cdap::repo'
end

package 'cdap-ambari-service' do
  action :install
  version node['cdap']['ambari']['version']
  notifies :restart, 'service[ambari-server]', :delayed if node['cdap']['ambari']['install_ambari'].to_s == 'true'
end
