#
# Cookbook Name:: cdap
# Provider:: merge_branch
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

use_inline_resources if defined?(use_inline_resources)

action :merge do
  gr = new_resource.git_resource
  branch = new_resource.branch

  # Run the git merge command
  execute "merge branch #{branch}" do
    command "git branch -f #{branch} origin/#{branch} && git merge #{branch}"
    cwd gr.destination
  end
end
