require 'spec_helper'

describe 'cdap::repo' do
  context 'on Centos 6.9 x86_64 using default version' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: 6.9).converge(described_recipe)
    end

    it 'adds cdap-6.0 yum repository' do
      expect(chef_run).to add_yum_repository('cdap-6.0')
    end

    it 'deletes cask yum repository' do
      expect(chef_run).to delete_file('/etc/yum.repos.d/cask.repo')
    end
  end

  %w(
    3.0.6-1
    3.3.3-1
  ).each do |ver|
    context "using #{ver.split('-').first}" do
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'centos', version: 6.9) do |node|
          node.override['cdap']['version'] = ver
        end.converge(described_recipe)
      end

      it "adds cdap-#{ver.to_f} yum repository" do
        expect(chef_run).to add_yum_repository("cdap-#{ver.to_f}")
      end
    end
  end

  context 'on Ubuntu 14.04 using default version' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: 14.04).converge(described_recipe)
    end

    it 'adds cdap-5.1 apt repository' do
      expect(chef_run).to add_apt_repository('cdap-5.1')
    end

    it 'deletes cask apt repository' do
      expect(chef_run).to delete_file('/etc/apt/sources.list.d/cask.list')
    end
  end
end
