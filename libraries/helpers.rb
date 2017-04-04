#
# Cookbook Name:: cdap
# Library:: helpers
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

module CDAP
  module Helpers
    #
    # Return true if Explore is enabled
    #
    def cdap_explore?
      return true if cdap_property?('explore.enabled') &&
                     node['cdap']['cdap_site']['explore.enabled'].to_s == 'true'
      # Explore is enabled by default in 3.3+ (CDAP-4355)
      return true if !cdap_property?('explore.enabled') &&
                     node['cdap']['version'].to_f >= 3.3
      false
    end

    #
    # Return true if Security is enabled
    #
    def cdap_security?
      return true if cdap_property?('security.enabled') &&
                     node['cdap']['cdap_site']['security.enabled'].to_s == 'true'
      false
    end

    #
    # Return true if SSL is enabled
    #
    def cdap_ssl?
      ssl_enabled =
        if node['cdap']['version'].to_f < 2.5 && cdap_property?('security.server.ssl.enabled')
          node['cdap']['cdap_site']['security.server.ssl.enabled']
        elsif node['cdap']['version'].to_f < 4.0 && cdap_property?('ssl.enabled')
          node['cdap']['cdap_site']['ssl.enabled']
        elsif cdap_property?('ssl.external.enabled')
          node['cdap']['cdap_site']['ssl.external.enabled']
        # Now, do fallback ssl.enabled then security.server.ssl.enabled
        elsif cdap_property?('ssl.enabled')
          node['cdap']['cdap_site']['ssl.enabled']
        elsif cdap_property?('security.server.ssl.enabled')
          node['cdap']['cdap_site']['security.server.ssl.enabled']
        end
      ssl_enabled.to_s == 'true' ? true : false
    end

    #
    # Return true if property is configured as a Java Keystore
    #
    def cdap_ssl_jks?(property)
      jks =
        if cdap_property?(property, 'cdap_security')
          node['cdap']['cdap_security'][property]
        else
          'JKS'
        end
      jks == 'JKS' ? true : false
    end

    #
    # Return hash with SSL options for JKS
    #
    def cdap_jks_opts(prefix)
      ssl = {}
      ssl['password'] = node['cdap']['cdap_security']["#{prefix}.ssl.keystore.password"]
      ssl['keypass'] =
        if cdap_property?("#{prefix}.ssl.keystore.keypassword")
          node['cdap']['cdap_security']["#{prefix}.ssl.keystore.keypassword"]
        else
          ssl['password']
        end
      ssl['path'] = node['cdap']['cdap_security']["#{prefix}.ssl.keystore.path"]
      ssl['common_name'] = node['cdap']['security']['ssl_common_name']
      ssl
    end

    #
    # Return hash with SSL options for OpenSSL
    #
    def cdap_ssl_opts(prefix = 'dashboard')
      ssl = {}
      ssl['keypath'] = node['cdap']['cdap_security']["#{prefix}.ssl.key"]
      ssl['certpath'] = node['cdap']['cdap_security']["#{prefix}.ssl.cert"]
      ssl['common_name'] = node['cdap']['security']['ssl_common_name']
      ssl
    end

    #
    # Return true if property is set
    #
    def cdap_property?(property, sitefile = 'cdap_site')
      return true if node['cdap'].key?(sitefile) && node['cdap'][sitefile].key?(property)
      false
    end
  end
end

# Load helpers
Chef::Recipe.send(:include, CDAP::Helpers)
Chef::Resource.send(:include, CDAP::Helpers)
