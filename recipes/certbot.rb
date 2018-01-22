# frozen_string_literal: true

#
# Cookbook Name:: letsencryptaws
# Recipe:: certbot
#
# Copyright 2018, Matt Kulka
#

# Dependencies for certbot
apt_update 'update' do
  action :periodic
end

python_runtime '2.7' do
  pip_version true
  options :system
end

python_package 'cryptography' do
  version '2.1.4'
  action :upgrade
end

python_package 'certbot'
python_package 'awscli'

package 'ruby'
gem_package 'aws-sdk-route53'

# Scripts for certbot hooks
directory node['letsencryptaws']['scripts_dir'] do
  recursive true
  owner 'root'
  group 'root'
  mode '755'
end

%w[
  certbot_route53_authenticator.rb
  certbot_route53_cleanup.rb
  dnschange.rb
].each do |file|
  cookbook_file ::File.join(node['letsencryptaws']['scripts_dir'], file) do
    owner 'root'
    group 'root'
    mode '755'
    source file
  end
end

# Local certificate storage
directory node['letsencryptaws']['config_dir'] do
  owner 'root'
  group 'root'
  mode '755'
  recursive true
end

execute "mkfs.ext4 #{node['letsencryptaws']['ebs_device']}" do
  not_if "fsck.ext4 -n #{node['letsencryptaws']['ebs_device']}"
  only_if { node.attribute?('ec2') && ::File.blockdev?(node['letsencryptaws']['ebs_device']) }
end

mount node['letsencryptaws']['config_dir'] do
  device node['letsencryptaws']['ebs_device']
  fstype 'ext4'
  action %i[mount enable]
  only_if { node.attribute?('ec2') && ::File.blockdev?(node['letsencryptaws']['ebs_device']) }
end

# Determine domains we need certificates for
certs_needed = {}
nodes = search(:node, 'letsencryptaws_certs_*:*') << node # ~FC003
nodes.each do |n|
  certs_needed.merge!(n['letsencryptaws']['certs']) do |_k, oldv, newv|
    oldv | newv
  end
end

# Get certificates from Let's Encrypt with certbot and sync to s3
return if node.attribute?('ec2') && !::File.blockdev?(node['letsencryptaws']['ebs_device'])

certs_needed.each_pair do |domain, sans|
  # Skip certs that may be ratelimited
  if node['letsencryptaws']['blacklist'].include?(domain)
    Chef::Log.warn("Skipping processing of #{domain} because it is blacklisted.")
    next
  end

  command = [
    'certbot certonly',
    '--manual',
    "--cert-name #{domain}",
    '--preferred-challenges=dns',
    "--manual-auth-hook #{::File.join(node['letsencryptaws']['scripts_dir'], 'certbot_route53_authenticator.rb')}",
    "--manual-cleanup-hook #{::File.join(node['letsencryptaws']['scripts_dir'], 'certbot_route53_cleanup.rb')}",
    "--email #{node['letsencryptaws']['email']}",
    '--agree-tos',
    '--non-interactive',
    '--expand',
    '--keep-until-expiring',
    "--config-dir #{node['letsencryptaws']['config_dir']}",
    '--manual-public-ip-logging-ok',
  ]
  command += ['--test-cert'] if node['letsencryptaws']['test_certs']
  command += ["-d #{domain}"]
  sans.reject { |s| s == '' || s.nil? }.each { |s| command << "-d #{s}" }

  execute "get certificate for #{domain}" do
    command command.join(' ')
    environment ({
      'AWS_ACCESS_KEY_ID' => node['aws_access_key_id'] || creds('aws_access_key_id'),
      'AWS_SECRET_ACCESS_KEY' => node['aws_secret_access_key'] || creds('aws_secret_access_key'),
    })
    live_stream true
  end
end

ruby_block 'remove unrequested certificates' do
  block do
    live_certs = []
    Dir.glob("#{node['letsencryptaws']['config_dir']}/live/*") do |fn|
      live_certs << ::File.basename(fn.sub(/-\d{4}$/, ''))
    end
    certs_to_delete = live_certs - certs_needed.keys

    unless certs_to_delete.empty?
      Chef::Log.warn('Removing the following domains as they are no longer requested by any node: ' +
                     certs_to_delete.join(', '))
    end
    certs_to_delete.each do |domain|
      Mixlib::ShellOut.new(
        "certbot delete -n --config-dir #{node['letsencryptaws']['config_dir']} --cert-name #{domain}"
      ).run_command.error!
    end
  end
  only_if { node['letsencryptaws']['remove_unused_certs'] }
end

kms = nil
unless node['letsencryptaws']['kms_key_id'].nil?
  kms = "--sse aws:kms --sse-kms-key-id #{node['letsencryptaws']['kms_key_id']}"
end

execute 'sync certificates to s3' do
  command [
    'aws s3 sync',
    '--delete',
    '--exclude \'default-ssl/*\'',
    kms,
    "#{node['letsencryptaws']['config_dir']}/live/",
    "s3://#{node['letsencryptaws']['sync_bucket']}/#{node['letsencryptaws']['sync_path']}",
  ].join(' ')
  environment ({
    'AWS_ACCESS_KEY_ID' => node['aws_access_key_id'] || creds('aws_access_key_id'),
    'AWS_SECRET_ACCESS_KEY' => node['aws_secret_access_key'] || creds('aws_secret_access_key'),
  })
  live_stream true
  only_if "[ -d #{node['letsencryptaws']['config_dir']}/live ]"
  not_if { node['letsencryptaws']['sync_bucket'].nil? }
end
