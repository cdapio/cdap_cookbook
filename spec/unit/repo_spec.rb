require 'spec_helper'

describe 'cdap::repo' do
  context 'on Centos 6.6 x86_64 using default version' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: 6.6).converge(described_recipe)
    end

    it 'adds cdap-4.3 yum repository' do
      expect(chef_run).to add_yum_repository('cdap-4.3')
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
        ChefSpec::SoloRunner.new(platform: 'centos', version: 6.6) do |node|
          node.override['cdap']['version'] = ver
        end.converge(described_recipe)
      end

      it "adds cdap-#{ver.to_f} yum repository" do
        expect(chef_run).to add_yum_repository("cdap-#{ver.to_f}")
      end
    end
  end

  context 'on Ubuntu 12.04 using default version' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: 12.04).converge(described_recipe)
    end

    it 'adds cdap-4.3 apt repository' do
      expect(chef_run).to add_apt_repository('cdap-4.3')
    end

    it 'deletes cask apt repository' do
      expect(chef_run).to delete_file('/etc/apt/sources.list.d/cask.list')
    end
  end
end
