#
# Cookbook Name:: cdap
# Library:: helpers
#
# Copyright © 2016 Cask Data, Inc.
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

module CDAP
  module Helpers
    #
    # Return true if SSL is enabled
    #
    def ssl_enabled?
      ssl_enabled =
        if node['cdap']['version'].to_f < 2.5 && node['cdap'].key?('cdap_site') &&
           node['cdap']['cdap_site'].key?('security.server.ssl.enabled')
          node['cdap']['cdap_site']['security.server.ssl.enabled']
        elsif node['cdap'].key?('cdap_site') && node['cdap']['cdap_site'].key?('ssl.enabled')
          node['cdap']['cdap_site']['ssl.enabled']
        # This one is here for compatibility, but ssl.enabled takes precedence, if set
        elsif node['cdap'].key?('cdap_site') && node['cdap']['cdap_site'].key?('security.server.ssl.enabled')
          node['cdap']['cdap_site']['security.server.ssl.enabled']
        else
          false
        end
      ssl_enabled.to_s == 'true' ? true : false
    end

    def jks?(property)
      jks =
        if node['cdap'].key?('cdap_security') && node['cdap']['cdap_security'].key?(property)
          node['cdap']['cdap_security'][property]
        else
          'JKS'
        end
      jks == 'JKS' ? true : false
    end
  end
end

# Load helpers
Chef::Recipe.send(:include, CDAP::Helpers)
Chef::Resource.send(:include, CDAP::Helpers)
