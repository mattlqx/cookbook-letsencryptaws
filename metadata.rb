# frozen_string_literal: true

name             'letsencryptaws'
maintainer       'Matt Kulka'
maintainer_email 'matt@lqx.net'
license          'MIT'
description      'Procures Let\'s Encrypt SSL certificates for Route 53-hosted domains'
version          '5.0.0'

supports     'ubuntu'
chef_version '>= 15.3'

issues_url 'https://github.com/mattlqx/cookbook-letsencryptaws/issues'
source_url 'https://github.com/mattlqx/cookbook-letsencryptaws'

depends 'aws', '~> 9.0'
depends 'pyenv', '~> 4.0'
