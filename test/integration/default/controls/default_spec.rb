describe directory('/opt/cdap') do
  it { should exist }
  it { should be_readable }
end

describe file('/opt/cdap/sandbox/conf/cdap-site.xml') do
  it { should exist }
end

describe service('cdap-sandbox') do
  it { should be_installed }
  it { should be_running }
end

[
  'ps auxww | grep -i cdap',
  '/opt/cdap/sandbox/bin/cdap cli list namespaces | grep "default"',
].each do |cmd|
  describe command(cmd) do
    its('exit_status') { should eq 0 }
  end
end
