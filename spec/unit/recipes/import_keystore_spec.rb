# frozen_string_literal: true

require 'spec_helper'

describe 'letsencryptaws::import_keystore' do
  platform 'ubuntu', '20.04'

  override_attributes['letsencryptaws']['certs']['test.example.com'] = []
  override_attributes['letsencryptaws']['data_bag'] = 'testbag'
  override_attributes['letsencryptaws']['data_bag_item'] = 'testitem'
  override_attributes['letsencryptaws']['import_keystore']['/tmp/foo'] = ['test.example.com']

  before do
    stub_data_bag_item('testbag', 'testitem').and_return(
      'p12_password' => 'foo',
      'keystore_passwords' => { 'default' => 'bar' }
    )
  end

  it 'installs java' do
    expect(chef_run).to install_package('openjdk-8-jre')
  end

  # Subscribes can't be tested because the target resource is outside this recipe
  it 'imports pkcs12 keyring into keystore' do
    expect(chef_run).to nothing_execute('import test.example.com into /tmp/foo')
  end
end
