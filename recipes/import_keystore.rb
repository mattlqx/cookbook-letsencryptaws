# frozen_string_literal: true

#
# Cookbook:: letsencryptaws
# Recipe:: import_keystore
#
# Copyright:: 2020, Matt Kulka
#

package node['letsencryptaws']['java_package']

node['letsencryptaws']['import_keystore'].each_pair do |keystore, domains|
  domains.each do |domain|
    execute "import #{domain} into #{keystore}" do
      command (lazy do
                 'keytool -importkeystore -noprompt' \
                   "  -srckeystore #{File.join(node['letsencryptaws']['ssl_key_dir'], "#{domain}.p12")} " \
                   "  -destkeystore #{keystore} -srcstorepass \"#{aws_creds('p12_password')}\" -deststorepass " \
                   "  \"#{aws_creds('keystore_passwords').fetch(keystore,
                                                                aws_creds('keystore_passwords')['default'])}\""
               end)
      subscribes :run, "execute[generate pkcs12 store for #{domain}]", :immediately
      sensitive true
      action :nothing
    end
  end
end
