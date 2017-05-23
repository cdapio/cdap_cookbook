require 'spec_helper'

describe 'cdap::prerequisites' do
  context 'using default cdap version' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: 6.6) do |node|
        node.automatic['domain'] = 'example.com'
        node.default['hadoop']['hdfs_site']['dfs.datanode.max.transfer.threads'] = '4096'
        node.default['hadoop']['mapred_site']['mapreduce.framework.name'] = 'yarn'
        node.override['cdap']['cdap_env']['log_dir'] = '/test/logs/cdap'
        stub_command(/update-alternatives --display /).and_return(false)
        stub_command(/test -L /).and_return(false)
      end.converge(described_recipe)
    end

    it 'logs JAVA_HOME' do
      expect(chef_run).to write_log(/JAVA_HOME = .*/)
    end

    it 'logs about Explore being enabled' do
      expect(chef_run).to write_log('Explore module enabled, installing Hive libraries')
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

    it 'does not log about Explore being enabled' do
      expect(chef_run).not_to write_log('Explore module enabled, installing Hive libraries')
    end
  end
end
