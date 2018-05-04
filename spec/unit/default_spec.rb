require 'spec_helper'

describe 'cdap::default' do
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

    it 'creates /test/logs/cdap directory' do
      expect(chef_run).to create_directory('/test/logs/cdap')
    end

    it 'deletes /var/log/cdap' do
      expect(chef_run).to delete_directory('/var/log/cdap')
    end

    it 'creates /var/log/cdap symlink' do
      link = chef_run.link('/var/log/cdap')
      expect(link).to link_to('/test/logs/cdap')
    end
  end
end
