#
# Cookbook Name:: cdap
# Attribute:: config
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

# Default: conf.chef
default['cdap']['conf_dir'] = 'conf.chef'
# Default: 4.3.4-1
default['cdap']['version'] = '4.3.4-1'
# cdap-site.xml
default['cdap']['cdap_site']['root.namespace'] = 'cdap'
# ideally we could put the macro '/${cdap.namespace}' here but this attribute is used elsewhere in the cookbook
default['cdap']['cdap_site']['hdfs.namespace'] = "/#{node['cdap']['cdap_site']['root.namespace']}"
default['cdap']['cdap_site']['hdfs.user'] = 'yarn'
default['cdap']['cdap_site']['kafka.seed.brokers'] = "#{node['fqdn']}:9092"
default['cdap']['cdap_site']['log.retention.duration.days'] = '7'
# COOK-85
if node['cdap']['version'].to_f < 4.0
  default['cdap']['cdap_site']['metadata.updates.kafka.broker.list'] = node['cdap']['cdap_site']['kafka.seed.brokers']
end
default['cdap']['cdap_site']['zookeeper.quorum'] = "#{node['fqdn']}:2181/#{node['cdap']['cdap_site']['root.namespace']}"
default['cdap']['cdap_site']['router.bind.address'] = node['fqdn']
default['cdap']['cdap_site']['router.server.address'] = node['fqdn']

# HDP 2.2+ support
# %{_FULL_VERSION} will be interpolated in the config recipe, when helper libraries are available
if node.key?('hadoop') && node['hadoop'].key?('distribution') && node['hadoop'].key?('distribution_version')
  if node['hadoop']['distribution'] == 'hdp' && node['hadoop']['distribution_version'].to_f >= 2.2 &&
     node['cdap']['version'].to_f >= 3.1
    default['cdap']['cdap_env']['opts'] = '${OPTS} -Dhdp.version=%<_FULL_VERSION>s'
    default['cdap']['cdap_site']['app.program.jvm.opts'] = '-XX:MaxPermSize=128M ${twill.jvm.gc.opts} -Dhdp.version=%<_FULL_VERSION>s'
    if node['cdap']['version'].to_f < 3.4
      default['cdap']['cdap_env']['spark_home'] = '/usr/hdp/%<_FULL_VERSION>s/spark'
    end
  elsif node['hadoop']['distribution'] == 'iop'
    iop_version = node['hadoop']['distribution_version']
    default['cdap']['cdap_env']['opts'] = "${OPTS} -Diop.version=#{iop_version}"
    default['cdap']['cdap_site']['app.program.jvm.opts'] = "-XX:MaxPermSize=128M ${twill.jvm.gc.opts} -Diop.version=#{iop_version}"
  elsif node['cdap']['version'].to_f < 3.4 # CDAP 3.4 determines SPARK_HOME on its own (CDAP-5086)
    default['cdap']['cdap_env']['spark_home'] = '/usr/lib/spark'
  end
end
