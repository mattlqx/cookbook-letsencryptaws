# frozen_string_literal: true

require 'ostruct'
require 'spec_helper'

describe 'letsencryptaws::default' do
  platform 'ubuntu', '20.04'

  override_attributes['letsencryptaws']['certs']['test.example.com'] = []
  override_attributes['letsencryptaws']['data_bag'] = 'testbag'
  override_attributes['letsencryptaws']['data_bag_item'] = 'testitem'
  override_attributes['letsencryptaws']['sync_bucket'] = 'foobucket'

  before do
    allow(Etc).to receive(:getpwnam).and_return(OpenStruct.new(uid: 0))
    allow(Etc).to receive(:getgrnam).and_return(OpenStruct.new(gid: 0))
    stub_data_bag_item('testbag', 'testitem').and_return('p12_password' => 'foo')
  end

  it 'creates directories' do
    expect(chef_run).to create_directory('/etc/ssl/certs')
    expect(chef_run).to create_directory('/etc/ssl/private')
  end

  it 'ensures ssl group' do
    expect(chef_run).to create_group('ssl-cert')
  end

  it 'downloads default certificates' do
    expect(chef_run).to create_remote_file_s3('/etc/ssl/certs/default.crt')
    expect(chef_run).to create_remote_file_s3('/etc/ssl/private/default.key')
    expect(chef_run).to create_remote_file_s3('/etc/ssl/certs/default.ca')
  end

  it 'does not update ca certificates' do
    expect(chef_run).to nothing_execute('update-ca-certificates')
  end

  it 'downloads requested certificates' do
    expect(chef_run).to create_remote_file_s3('/etc/ssl/certs/test.example.com.crt')
    expect(chef_run).to create_remote_file_s3('/etc/ssl/private/test.example.com.key')
    expect(chef_run).to create_remote_file_s3('/etc/ssl/certs/test.example.com.ca')
  end

  it 'composes requested certificates' do
    expect(chef_run).to create_if_missing_file('/etc/ssl/certs/test.example.com.crt')
    expect(chef_run).to create_if_missing_file('/etc/ssl/private/test.example.com.key')
    expect(chef_run).to create_if_missing_file('/etc/ssl/certs/test.example.com.ca')
    expect(chef_run).to create_file('/etc/ssl/certs/test.example.com.crt-chain')
  end

  it 'generates pkcs12 keyring' do
    expect(chef_run).to nothing_execute('generate pkcs12 store for test.example.com')
    expect(chef_run.execute('generate pkcs12 store for test.example.com')).to \
      subscribe_to('remote_file_s3[/etc/ssl/certs/test.example.com.crt]').on(:run).delayed
    expect(chef_run).to nothing_notify_group('pkcs12 store needs generated for test.example.com')
    expect(chef_run.notify_group('pkcs12 store needs generated for test.example.com')).to \
      notify('execute[generate pkcs12 store for test.example.com]').to(:run).immediately
    expect(chef_run).to create_file('/etc/ssl/private/test.example.com.p12')
  end

  context 'when testing' do
    override_attributes['letsencryptaws']['test_certs'] = true

    it 'updates ca certificates' do
      expect(chef_run).to create_remote_file('/usr/local/share/ca-certificates/fakeroot.crt')
      expect(chef_run.remote_file('/usr/local/share/ca-certificates/fakeroot.crt')).to \
        notify('execute[update-ca-certificates]').to(:run).immediately
    end
  end
end
