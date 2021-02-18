# frozen_string_literal: true

#
# Cookbook:: letsencryptaws
# Recipe:: certbot
#
# Copyright:: 2020, Matt Kulka
#

# Dependencies for certbot
apt_update 'update' do
  action :periodic
end

python_major = node['letsencryptaws']['python_version'].split('.').first.to_i

pyenv_system_install 'system'

pyenv_python node['letsencryptaws']['python_version']

pyenv_global node['letsencryptaws']['python_version']

pyenv_pip 'parsedatetime' do
  version '2.5'
  only_if do
    node['letsencryptaws']['python_version'].to_s.start_with?('2.7') || \
      node['letsencryptaws']['python_version'].to_s == '2'
  end
end

pyenv_pip 'cryptography' do
  version python_major >= 3 ? '3.4.6' : '2.8'
end

pyenv_pip 'idna' do
  version python_major >= 3 ? '2.9' : '2.6'
end

pyenv_pip 'certbot' do
  version node['letsencryptaws']['certbot_version']
end

pyenv_pip 'certbot-dns-route53'
pyenv_pip 'awscli'

link '/usr/local/bin/certbot' do
  to "/usr/local/pyenv/versions/#{node['letsencryptaws']['python_version']}/bin/certbot"
  only_if { node['letsencryptaws']['link_pybins'] }
end

link '/usr/local/bin/aws' do
  to "/usr/local/pyenv/versions/#{node['letsencryptaws']['python_version']}/bin/aws"
  only_if { node['letsencryptaws']['link_pybins'] }
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
  action %i(mount enable)
  only_if { node.attribute?('ec2') && ::File.blockdev?(node['letsencryptaws']['ebs_device']) }
end

# Determine domains we need certificates for
certs_needed = {}
nodes = search(:node, 'letsencryptaws_certs_*:*') << node
nodes.each do |n|
  certs_needed.merge!(n['letsencryptaws']['certs']) do |_k, oldv, newv|
    oldv | newv
  end
end

# Get certificates from Let's Encrypt with certbot and sync to s3
return if node.attribute?('ec2') && !::File.blockdev?(node['letsencryptaws']['ebs_device'])

certs_needed.each_pair do |domain, sans|
  # Skip certs that may be ratelimited
  if node['letsencryptaws']['blocklist'].include?(domain)
    Chef::Log.warn("Skipping processing of #{domain} because it is blocklisted.")
    next
  end

  command = [
    "/usr/local/pyenv/versions/#{node['letsencryptaws']['python_version']}/bin/certbot certonly",
    "--cert-name #{domain.sub('*', 'star')}",
    '--preferred-challenges dns',
    '--dns-route53',
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
    environment (lazy do
      {
        'AWS_ACCESS_KEY_ID' => node['aws_access_key_id'] || aws_creds('aws_access_key_id'),
        'AWS_SECRET_ACCESS_KEY' => node['aws_secret_access_key'] || aws_creds('aws_secret_access_key'),
        'AWS_SESSION_TOKEN' => node['aws_session_token'] || aws_creds('aws_session_token'),
      }
    end)
    live_stream true
  end
end

ruby_block 'remove unrequested certificates' do
  block do
    live_certs = []
    Dir.glob("#{node['letsencryptaws']['config_dir']}/live/*") do |fn|
      next if ::File.basename(fn) == 'README'
      live_certs << ::File.basename(fn.sub(/-\d{4}$/, ''))
    end
    certs_to_delete = live_certs - certs_needed.keys.map { |cn| cn.sub('*', 'star') }

    unless certs_to_delete.empty?
      Chef::Log.warn('Removing the following domains as they are no longer requested by any node: ' +
                     certs_to_delete.join(', '))
    end
    certs_to_delete.each do |domain|
      shell_out("certbot delete -n --config-dir #{node['letsencryptaws']['config_dir']} --cert-name #{domain}").error!
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
    "/usr/local/pyenv/versions/#{node['letsencryptaws']['python_version']}/bin/aws s3 sync",
    '--delete',
    '--exclude \'default-ssl/*\'',
    kms,
    "#{node['letsencryptaws']['config_dir']}/live/",
    "s3://#{node['letsencryptaws']['sync_bucket']}/#{node['letsencryptaws']['sync_path']}",
  ].join(' ')
  environment (lazy do
    {
      'AWS_ACCESS_KEY_ID' => node['aws_access_key_id'] || aws_creds('aws_access_key_id'),
      'AWS_SECRET_ACCESS_KEY' => node['aws_secret_access_key'] || aws_creds('aws_secret_access_key'),
      'AWS_SESSION_TOKEN' => node['aws_session_token'] || aws_creds('aws_session_token'),
    }
  end)
  live_stream true
  only_if "[ -d #{node['letsencryptaws']['config_dir']}/live ]"
  not_if { node['letsencryptaws']['sync_bucket'].nil? }
end
