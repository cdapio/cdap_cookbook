#
# Cookbook Name:: cdap
# Attribute:: source
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

# Symlink Maven
default['maven']['setup_bin'] = true

# String of Maven options to be appended to "-DskipTests=true"
default['cdap']['source']['maven_extra_opts'] = ''

# Control build behavior
default['cdap']['source']['merge_open_prs'] = false
default['cdap']['source']['force_rebuild'] = false
default['cdap']['source']['skip_build'] = false

# Git configuration
default['cdap']['source']['git']['local_user'] = 'root'
default['cdap']['source']['git']['local_group'] = 'root'

# CDAP Build source repository definition
default['cdap']['source']['git']['repo']['cdap-build'] = {
  'uri' => 'https://github.com/caskdata/cdap-build.git',
  'branch' => 'develop',
  'dir' => '/data/git/cdap-build',
  'depth' => '',
  'sync' => true,
  'submodules' => {
    'cdap' => {
      'branch' => '',
      'sync'   => true
    },
    'app-artifacts/cask-tracker' => {
      'branch' => '',
      'sync'   => true
    },
    'app-artifacts/cdap-navigator' => {
      'branch' => '',
      'sync'   => true
    },
    'app-artifacts/hydrator-plugins' => {
      'branch' => '',
      'sync'   => true
    },
    'security-extensions/cdap-security-extn' => {
      'branch' => '',
      'sync'   => true
    }
  }
}

# CDAP Ambari Service source repository definition
default['cdap']['source']['git']['repo']['cdap-ambari-service'] = {
  'uri'    => 'https://github.com/caskdata/cdap-ambari-service.git',
  'branch' => 'develop',
  'dir' => '/data/git/cdap-ambari-service',
  'depth'  => '',
  'sync'   => true
}
