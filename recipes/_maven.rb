#
# Cookbook Name:: cdap_auto
# Recipe:: _maven
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

# Include build depencies
include_recipe 'maven'

repo = node['cdap']['source']['git']['repo']['cdap-build']
local_user =
  if node['cdap']['source']['git']['local_user'] == 'admin'
    'root'
  else
    node['cdap']['source']['git']['local_user']
  end
local_group = node['cdap']['source']['git']['local_group']
ver = node['cdap']['version'].to_f

include_recipe 'cdap::_git'
include_recipe 'cdap::_fpm'

%w(app-artifacts security-extensions).each do |dir|
  directory "#{repo['dir']}/#{dir}" do
    action :create
    owner local_user
    group local_group
    mode '0755'
    only_if { ver >= 3.3 }
  end
end

mvn_action =
  if node['cdap']['source']['force_build']
    :run
  else
    :nothing
  end

# Clean the working dir to avoid Apache RAT failures
execute 'git-clean-fd' do
  action mvn_action
  command 'git clean -fd'
  cwd repo['dir']
  user local_user
  group local_group
  subscribes :run, 'log[git-notifier-autobuild]', :immediately unless node['cdap']['source']['force_build'].to_s == 'true'
end

# Install logrotate configuration for maven-autobuild.log
cookbook_file '/etc/logrotate.d/autobuild' do
  source 'logrotate-autobuild'
  mode '0644'
  action :create
end

# Remove co.cask.* from Maven cache
bash 'maven-remove-cask-cached-artifacts' do
  action mvn_action
  code <<-EOH
    set -o pipefail
    echo "$(date) Removing previous Cask artifacts from Maven cache" | tee -a /var/log/maven-autobuild.log
    rm -rvf ~#{local_user}/.m2/repository/co/cask/* | tee -a /var/log/maven-autobuild.log
  EOH
  user local_user
  group local_group
  subscribes :run, 'execute[git-clean-fd]', :immediately unless node['cdap']['source']['force_build'].to_s == 'true'
end

# Build/Install Apache Sentry JARs, if necessary
sentry_cmd = 'mvn install -DskipTests -f apache-sentry'
sentry_ver = '1.7.0'

mvn_path = "#{node['maven']['m2_home']}/bin"

bash 'maven-install-apache-sentry' do
  action mvn_action
  code <<-EOH
    set -o pipefail
    echo "$(date) Running: #{sentry_cmd}" | tee -a /var/log/maven-autobuild.log
    #{sentry_cmd} | tee -a /var/log/maven-autobuild.log
  EOH
  cwd repo['dir']
  user local_user
  group local_group
  environment('MAVEN_OPTS' => '-Xmx1024m -XX:MaxPermSize=128m',
              'PATH' => "#{mvn_path}:/opt/chef/embedded/bin:#{ENV['PATH']}")
  only_if "test -d #{repo['dir']}/apache-sentry"
  not_if "test -d ~#{local_user}/.m2/repository/org/apache/sentry/sentry-provider-db/#{sentry_ver}/sentry-provider-db-#{sentry_ver}.jar"
  subscribes :run, 'log[git-notifier-autobuild]', :immediately unless node['cdap']['source']['force_build'].to_s == 'true'
end

# Build/Install CDAP packages w/ minimal profiles, for external projects to build against
cdap_cmd = 'mvn install -DskipTests -B -P templates -V -U'

bash 'maven-install-cdap-minimal' do
  action mvn_action
  code <<-EOH
    set -o pipefail
    echo "$(date) Running: #{cdap_cmd}" | tee -a /var/log/maven-autobuild.log
    #{cdap_cmd} | tee -a /var/log/maven-autobuild.log
  EOH
  cwd "#{repo['dir']}/cdap"
  user local_user
  group local_group
  environment('MAVEN_OPTS' => '-Xmx4096m -XX:MaxPermSize=256m',
              'PATH' => "#{mvn_path}:/opt/chef/embedded/bin:#{ENV['PATH']}")
  only_if { ver >= 3.3 }
  timeout 3600
  subscribes :run, 'bash[maven-remove-cask-cached-artifacts]', :immediately unless node['cdap']['source']['force_build'].to_s == 'true'
end

# Configure Maven command for main CDAP build
mvn_extra_opts = node['cdap']['source']['maven_extra_opts']
profiles = %w(dist examples)
case node['platform_family']
when 'debian'
  profiles += %w(deb-prepare deb)
when 'rhel'
  profiles += %w(rpm-prepare rpm)
end
profiles += %w(templates unit-tests) if ver >= 3.0

cdap_cmd = "mvn package -DskipTests -B -P #{profiles.join(',')} -V -U #{mvn_extra_opts}"
cdap_cmd += " -Dadditional.artifacts.dir=#{repo['dir']}/app-artifacts" if ver >= 3.3
cdap_cmd += " -Dsecurity.extensions.dir=#{repo['dir']}/security-extensions" if ver >= 3.5

# TODO: parameterize the maven build log, confirm directory existence, etc
bash 'maven-build-cdap-packages' do
  action mvn_action
  code <<-EOH
    set -o pipefail
    echo "$(date) Running: #{cdap_cmd}" | tee -a /var/log/maven-autobuild.log
    #{cdap_cmd} | tee -a /var/log/maven-autobuild.log
  EOH
  cwd repo['dir']
  user local_user
  group local_group
  environment('MAVEN_OPTS' => '-Xmx4096m -XX:MaxPermSize=256m',
              'PATH' => "#{mvn_path}:/opt/chef/embedded/bin:#{ENV['PATH']}")
  timeout 7200
  subscribes :run, 'log[git-notifier-autobuild]', :immediately unless node['cdap']['source']['force_build'].to_s == 'true'
end

# Explicitly install any CDAP dependencies, as we will no longer be installing from a repo
pkg_deps =
  if node['platform_family'] == 'debian'
    %w(libxml2-utils)
  elsif node['platform_family'] == 'rhel'
    %w(libxml2)
  else
    []
  end
pkg_deps.each do |pkg|
  package pkg do
    action :install
  end
end

# This block updates the package resources in this cookbook with the built from source versions
# - identifies packages in the repository
# - loops through packages and determines package resource name
# - adds source attribute to package's resource
#
# Example: cdap/cdap-master/target/cdap-master_2.8.0-1_all.deb adds source to package[cdap-master] resource
ruby_block 'modify-cdap-package-resources' do # ~FC014
  block do
    pkg_files =
      if node['platform_family'] == 'debian'
        ::Dir["#{repo['dir']}/cdap/*/target/cdap*.deb"]
      elsif node['platform_family'] == 'rhel'
        ::Dir["#{repo['dir']}/cdap/*/target/cdap*.rpm"]
      else
        []
      end

    pkg_files.each do |f|
      p = f.split('/')[-3]
      p = 'cdap' if p == 'cdap-distributions'
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
