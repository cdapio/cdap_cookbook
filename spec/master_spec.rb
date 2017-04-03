require 'spec_helper'

describe 'cdap::master' do
  context 'using default cdap version' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: 6.6) do |node|
        node.automatic['domain'] = 'example.com'
        node.default['hadoop']['hdfs_site']['dfs.datanode.max.transfer.threads'] = '4096'
        node.default['hadoop']['mapred_site']['mapreduce.framework.name'] = 'yarn'
        stub_command(/update-alternatives --display /).and_return(false)
        stub_command(/test -L /).and_return(false)
      end.converge(described_recipe)
    end
    pkgs = 'cdap-master, cdap-hbase-compat-0.96, cdap-hbase-compat-0.98'
    pkgs += ', cdap-hbase-compat-1.0, cdap-hbase-compat-1.0-cdh' # >= 3.1
    pkgs += ', cdap-hbase-compat-1.1' # >= 3.2
    pkgs += ', cdap-hbase-compat-1.0-cdh5.5.0' # >= 3.3
    pkgs += ', cdap-hbase-compat-1.2-cdh5.7.0'
    it "installs #{pkgs} packages" do
      expect(chef_run).to install_package(pkgs)
    end

    it 'does not install cdap-hbase-compat-0.94 package' do
      expect(chef_run).not_to install_package('cdap-hbase-compat-0.94')
    end

    it 'creates /etc/init.d/cdap-master from template' do
      expect(chef_run).to create_template('/etc/init.d/cdap-master')
    end

    it 'creates cdap-master service, but does not run it' do
      expect(chef_run).not_to start_service('cdap-master')
    end

    it 'creates cdap-upgrade-tool resource, but does not execute it' do
      expect(chef_run).not_to run_execute('cdap-upgrade-tool')
    end
  end

  context 'using CDAP 3.0' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: 6.6) do |node|
        node.automatic['domain'] = 'example.com'
        node.default['hadoop']['hdfs_site']['dfs.datanode.max.transfer.threads'] = '4096'
        node.default['hadoop']['mapred_site']['mapreduce.framework.name'] = 'yarn'
        node.override['cdap']['version'] = '3.0.6-1'
        stub_command(/update-alternatives --display /).and_return(false)
        stub_command(/test -L /).and_return(false)
      end.converge(described_recipe)
    end
    pkgs = 'cdap-master, cdap-hbase-compat-0.94, cdap-hbase-compat-0.96, cdap-hbase-compat-0.98'
    # [
    #   'cdap-master',
    #   'cdap-hbase-compat-0.94',
    #  'cdap-hbase-compat-0.96',
    #   'cdap-hbase-compat-0.98'
    # ]

    it "installs #{pkgs} packages" do
      expect(chef_run).to install_package(pkgs)
    end
  end
end
