# frozen_string_literal: true

name             'letsencryptaws'
maintainer       'Matt Kulka'
maintainer_email 'matt@lqx.net'
license          'MIT'
description      'Procures Let\'s Encrypt SSL certificates for Route 53-hosted domains'
version          '2.0.3'

supports     'ubuntu'
chef_version '>= 12'

issues_url 'https://github.com/mattlqx/cookbook-letsencryptaws/issues'
source_url 'https://github.com/mattlqx/cookbook-letsencryptaws'

depends 'pyenv', '~> 3.2'
depends 'remote_file_s3', '~> 1.0'
