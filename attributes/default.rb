# frozen_string_literal: true

# Paths
default['letsencryptaws']['config_dir'] = '/mnt/letsencrypt'
default['letsencryptaws']['ebs_device'] = '/dev/xvdf'

# Software versions
default['letsencryptaws']['certbot_version'] = '1.18.0'
default['letsencryptaws']['certbot_dns_version'] = node['letsencryptaws']['certbot_version']
default['letsencryptaws']['python_version'] = '3.8.3'

# Should aws and certbot in /usr/local/bin be linked to their pyenv paths?
default['letsencryptaws']['link_pybins'] = true

# Should test certificates be fetched (beware: non-test certs have ratelimits)
default['letsencryptaws']['test_certs'] = false

# Should certificates that are no longer requested by any node be removed?
default['letsencryptaws']['remove_unused_certs'] = true

# Email used by certbot during certificate request
default['letsencryptaws']['email'] = 'nobody@example.com'

# AWS and Java keystore credentials
default['letsencryptaws']['data_bag'] = nil
default['letsencryptaws']['data_bag_item'] = nil

# S3 certificate sync
default['letsencryptaws']['sync_bucket'] = nil
default['letsencryptaws']['sync_path'] = 'letsencrypt'
default['letsencryptaws']['kms_key_id'] = nil

# Don't fetch certificates with these exactly matching primary names
default['letsencryptaws']['blocklist'] = []

# This is where certificates will be requested by your nodes
default['letsencryptaws']['certs'] = {}
default['letsencryptaws']['import_keystore'] = {}

# Package to install for keytool
default['letsencryptaws']['java_package'] = 'openjdk-8-jre'

case node['platform']
when 'windows'
  default['letsencryptaws']['ssl_cert_dir'] = 'c:\ssl\certs'
  default['letsencryptaws']['ssl_key_dir'] = 'c:\ssl\keys'
  default['letsencryptaws']['ssl_ca_dir'] = 'c:\ssl\certs'
  default['letsencryptaws']['root_ca_dir'] = 'c:\ssl\certs'
  default['letsencryptaws']['ssl_owner'] = 'SYSTEM'
  default['letsencryptaws']['ssl_group'] = nil
  default['letsencryptaws']['aws_credentials_file'] = 'C:\chef\awscredentials'
when 'ubuntu'
  default['letsencryptaws']['ssl_cert_dir'] = '/etc/ssl/certs'
  default['letsencryptaws']['ssl_key_dir'] = '/etc/ssl/private'
  default['letsencryptaws']['ssl_ca_dir'] = '/etc/ssl/certs'
  default['letsencryptaws']['root_ca_dir'] = '/etc/ssl/certs'
  default['letsencryptaws']['ssl_owner'] = 'root'
  default['letsencryptaws']['ssl_group'] = 'ssl-cert'
  default['letsencryptaws']['aws_credentials_file'] = '/tmp/aws/credentials'
end
