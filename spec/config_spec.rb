require 'spec_helper'

describe 'cdap::config' do
  context 'using default cdap version' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: 6.6) do |node|
        node.automatic['domain'] = 'example.com'
        node.default['hadoop']['hdfs_site']['dfs.datanode.max.transfer.threads'] = '4096'
        node.default['hadoop']['mapred_site']['mapreduce.framework.name'] = 'yarn'
        node.default['cdap']['cdap_site']['hdfs.user'] = 'cdap'
        node.default['cdap']['cdap_env']['log_dir'] = '/test/logs/cdap'
        node.default['cdap']['cdap_security']['some.thing'] = 'foobar'
        stub_command(/update-alternatives --display /).and_return(false)
      end.converge(described_recipe)
    end

    it 'creates /etc/cdap/conf.chef directory' do
      expect(chef_run).to create_directory('/etc/cdap/conf.chef')
    end

    it 'runs execute[copy logback.xml from conf.dist]' do
      expect(chef_run).to run_execute('copy logback.xml from conf.dist')
    end

    %w(
      cdap-env.sh
      cdap-security.xml
      cdap-site.xml
    ).each do |tmpl|
      it "creates /etc/cdap/conf.chef/#{tmpl}" do
        expect(chef_run).to create_template("/etc/cdap/conf.chef/#{tmpl}")
      end
    end

    it 'runs execute[copy logback-container.xml from conf.dist]' do
      expect(chef_run).to run_execute('copy logback-container.xml from conf.dist')
    end

    it 'runs execute[update cdap-conf alternatives]' do
      expect(chef_run).to run_execute('update cdap-conf alternatives')
    end
  end
end
