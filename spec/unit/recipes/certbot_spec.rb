# frozen_string_literal: true

require 'spec_helper'

describe 'letsencryptaws::certbot' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  before do
    allow(File).to receive(:blockdev?).with('/dev/xvdf').and_return(true)
    stub_data_bag_item('testbag', 'testitem').and_return('p12_password' => 'foo')
    stub_search('node', 'letsencryptaws_certs_*:*').and_return([])
    stub_command('[ -d /mnt/letsencrypt/live ]').and_return(true)
    stub_command('fsck.ext4 -n /dev/xvdf').and_return(false)
    chef_run.node.default['ec2'] = {}
    chef_run.node.normal['letsencryptaws']['sync_bucket'] = 'foo'
    chef_run.node.normal['letsencryptaws']['certs']['test.example.com'] = []
    chef_run.node.normal['letsencryptaws']['data_bag'] = 'testbag'
    chef_run.node.normal['letsencryptaws']['data_bag_item'] = 'testitem'
    chef_run.converge(described_recipe)
  end

  it 'updates apt repo' do
    expect(chef_run).to periodic_apt_update('update')
  end

  it 'installs needed packages' do
    expect(chef_run).to install_python_runtime('2.7')
    expect(chef_run).to upgrade_python_package('cryptography')
    expect(chef_run).to install_python_package('certbot')
    expect(chef_run).to install_python_package('awscli')
    expect(chef_run).to install_package('ruby')
    expect(chef_run).to install_gem_package('aws-sdk-route53')
  end

  it 'creates directories' do
    expect(chef_run).to create_directory('/mnt/letsencrypt')
    expect(chef_run).to create_directory('/mnt/letsencrypt/scripts')
  end

  it 'creates filesystem and mounts' do
    expect(chef_run).to run_execute('mkfs.ext4 /dev/xvdf')
    expect(chef_run).to mount_mount('/mnt/letsencrypt')
  end

  it 'creates ruby scripts for certbot' do
    expect(chef_run).to create_cookbook_file('/mnt/letsencrypt/scripts/certbot_route53_authenticator.rb')
    expect(chef_run).to create_cookbook_file('/mnt/letsencrypt/scripts/certbot_route53_cleanup.rb')
    expect(chef_run).to create_cookbook_file('/mnt/letsencrypt/scripts/dnschange.rb')
  end

  it 'fetches certificate for requested domain' do
    expect(chef_run).to run_execute('get certificate for test.example.com')
  end

  it 'removes unrequested certificates' do
    expect(chef_run).to run_ruby_block('remove unrequested certificates')
  end

  it 'syncs certificates to s3' do
    expect(chef_run).to run_execute('sync certificates to s3')
  end
end
