# frozen_string_literal: true

require 'spec_helper'

describe 'letsencryptaws::certbot' do
  platform 'ubuntu', '20.04'

  default_attributes['ec2'] = {}
  default_attributes['pyenv']['git_url'] = 'https://github.com/pyenv/pyenv.git'
  default_attributes['pyenv']['git_ref'] = 'master'
  override_attributes['letsencryptaws']['sync_bucket'] = 'foo'
  override_attributes['letsencryptaws']['certs']['test.example.com'] = []
  override_attributes['letsencryptaws']['data_bag'] = 'testbag'
  override_attributes['letsencryptaws']['data_bag_item'] = 'testitem'

  before do
    allow(File).to receive(:blockdev?).with('/dev/xvdf').and_return(true)
    stub_data_bag_item('testbag', 'testitem').and_return('p12_password' => 'foo')
    stub_search('node', 'letsencryptaws_certs_*:*').and_return([])
    stub_command('[ -d /mnt/letsencrypt/live ]').and_return(true)
    stub_command('fsck.ext4 -n /dev/xvdf').and_return(false)
  end

  it 'updates apt repo' do
    expect(chef_run).to periodic_apt_update('update')
  end

  it 'installs needed packages' do
    expect(chef_run).to install_pyenv_install('system')
    expect(chef_run).to install_pyenv_python('3.8.3')
    expect(chef_run).to install_pyenv_pip('cryptography')
    expect(chef_run).to install_pyenv_pip('certbot')
    expect(chef_run).to install_pyenv_pip('certbot-dns-route53')
    expect(chef_run).to install_pyenv_pip('awscli')
    expect(chef_run).to install_pyenv_pip('idna')
  end

  it 'creates directories' do
    expect(chef_run).to create_directory('/mnt/letsencrypt')
  end

  it 'creates filesystem and mounts' do
    expect(chef_run).to run_execute('mkfs.ext4 /dev/xvdf')
    expect(chef_run).to mount_mount('/mnt/letsencrypt')
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
