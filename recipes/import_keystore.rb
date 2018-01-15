# frozen_string_literal: true

#
# Cookbook Name:: letsencryptaws
# Recipe:: import_keystore
#
# Copyright 2018, Matt Kulka
#

package node['letsencryptaws']['java_package']

node['letsencryptaws']['import_keystore'].each_pair do |keystore, domains|
  domains.each do |domain|
    execute "import #{domain} into #{keystore}" do
      command 'keytool -importkeystore -noprompt' \
              "  -srckeystore #{File.join(node['letsencryptaws']['ssl_key_dir'], "#{domain}.p12")} " \
              "  -destkeystore #{keystore} -srcstorepass \"#{creds('p12_password')}\" -deststorepass " \
              "  \"#{creds('keystore_passwords').fetch(keystore, creds('keystore_passwords')['default'])}\"" # rubocop:disable Metrics/LineLength
      subscribes :run, "execute[generate pkcs12 store for #{domain}]", :immediately
      sensitive true
      action :nothing
    end
  end
end
