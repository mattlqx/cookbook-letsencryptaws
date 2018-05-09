# frozen_string_literal: true

name             'letsencryptaws'
maintainer       'Matt Kulka'
maintainer_email 'matt@lqx.net'
license          'MIT'
description      'Procures Let\'s Encrypt SSL certificates for Route 53-hosted domains'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.6'

supports     'ubuntu' if respond_to?(:supports)
chef_version '>= 12'

issues_url 'https://github.com/mattlqx/cookbook-letsencryptaws/issues' if respond_to?(:issues_url)
source_url 'https://github.com/mattlqx/cookbook-letsencryptaws' if respond_to?(:source_url)

depends 'poise-python', '~> 1.6'
depends 'remote_file_s3', '~> 1.0.5'
