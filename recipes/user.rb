#
# Cookbook Name:: cdap
# Recipe:: user
#
# Copyright © 2017 Cask Data, Inc.
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

# Create group and user, unconditionally, unless they exist already
group node['cdap']['cdap_user']['group'] do
  gid node['cdap']['cdap_user']['gid']
  action :create
  not_if "getent group #{node['cdap']['cdap_user']['group']}"
end

user node['cdap']['cdap_user']['username'] do
  uid node['cdap']['cdap_user']['uid']
  gid node['cdap']['cdap_user']['gid']
  password node['cdap']['cdap_user']['password'] if node['cdap']['cdap_user']['password']
  not_if "getent passwd #{node['cdap']['cdap_user']['username']}"
  action :create
end
