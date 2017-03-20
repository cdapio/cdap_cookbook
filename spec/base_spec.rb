require 'spec_helper'

describe 'cdap::base' do
  context 'using default cdap version' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: 6.6) do |node|
        node.automatic['domain'] = 'example.com'
        stub_command(/update-alternatives --display /).and_return(false)
        stub_command(/test -L /).and_return(false)
      end.converge(described_recipe)
    end

    it 'creates /etc/profile.d/cdap_home.sh file' do
      expect(chef_run).to create_file('/etc/profile.d/cdap_home.sh')
    end

    it 'installs cdap package' do
      expect(chef_run).to install_package('cdap')
    end
  end
end
