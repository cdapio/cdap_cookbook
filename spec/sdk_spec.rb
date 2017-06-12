require 'spec_helper'

describe 'cdap::sdk' do
  context 'using sdk version 4.1.0' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: 6.6) do |node|
        node.automatic['domain'] = 'example.com'
        node.override['cdap']['version'] = '4.1.0-2'
        node.default['cdap']['sdk']['install_dir'] = '/opt/cdap'
        stub_command('test -e /usr/bin/node').and_return(true)
      end.converge(described_recipe)
    end

    it 'creates /etc/init.d/cdap-sdk from template' do
      expect(chef_run).to create_template('/etc/init.d/cdap-sdk')
    end

    it 'creates /etc/profile.d/cdap-sdk.sh from template' do
      expect(chef_run).to create_template('/etc/profile.d/cdap-sdk.sh')
    end

    it 'sets NODE_ENV in /etc/profile.d/cdap-sdk.sh' do
      expect(chef_run).to render_file('/etc/profile.d/cdap-sdk.sh')
        .with_content(
          /NODE_ENV=/
        )
    end

    it 'creates cdap-sdk service and starts it' do
      expect(chef_run).to start_service('cdap-sdk')
      expect(chef_run).to enable_service('cdap-sdk')
    end
  end

  context 'using default cdap version' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: 6.6) do |node|
        node.automatic['domain'] = 'example.com'
        node.default['cdap']['sdk']['install_dir'] = '/opt/cdap'
        stub_command('test -e /usr/bin/node').and_return(true)
      end.converge(described_recipe)
    end

    it 'does not create /usr/bin/node link' do
      expect(chef_run).not_to create_link('/usr/bin/node').with(
        to: '/usr/local/bin/node'
      )
    end

    it 'creates /opt/cdap directory' do
      expect(chef_run).to create_directory('/opt/cdap')
    end

    it 'creates cdap user' do
      expect(chef_run).to create_user('cdap')
    end

    it 'creates /etc/init.d/cdap-sandbox from template' do
      expect(chef_run).to create_template('/etc/init.d/cdap-sandbox')
    end

    it 'creates /etc/profile.d/cdap-sandbox.sh from template' do
      expect(chef_run).to create_template('/etc/profile.d/cdap-sandbox.sh')
    end

    it 'sets NODE_ENV in /etc/profile.d/cdap-sandbox.sh' do
      expect(chef_run).to render_file('/etc/profile.d/cdap-sandbox.sh')
        .with_content(
          /NODE_ENV=/
        )
    end

    it 'creates cdap-sandbox service and starts it' do
      expect(chef_run).to start_service('cdap-sandbox')
      expect(chef_run).to enable_service('cdap-sandbox')
    end

    # There is no ark matcher, so we cannot test for it
    # ark[sdk]                           cdap/recipes/sdk.rb:48
  end
end
