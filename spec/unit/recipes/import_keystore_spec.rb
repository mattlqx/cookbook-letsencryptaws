# frozen_string_literal: true

require 'spec_helper'

describe 'letsencryptaws::import_keystore' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  before do
    stub_data_bag_item('testbag', 'testitem').and_return(
      'p12_password' => 'foo',
      'keystore_passwords' => { 'default' => 'bar' }
    )
    chef_run.node.normal['letsencryptaws']['certs']['test.example.com'] = []
    chef_run.node.normal['letsencryptaws']['data_bag'] = 'testbag'
    chef_run.node.normal['letsencryptaws']['data_bag_item'] = 'testitem'
    chef_run.node.normal['letsencryptaws']['import_keystore']['/tmp/foo'] = ['test.example.com']
    chef_run.converge(described_recipe)
  end

  it 'installs java' do
    expect(chef_run).to install_package('openjdk-8-jre')
  end

  # Subscribes can't be tested because the target resource is outside this recipe
  it 'imports pkcs12 keyring into keystore' do
    expect(chef_run).to nothing_execute('import test.example.com into /tmp/foo')
  end
end
