# frozen_string_literal: true

apt_update 'update'
package 'openjdk-8-jre'
directory '/tmp/letsencryptaws'

execute 'generate keystore for default password' do
  cwd '/tmp/letsencryptaws'
  command 'keytool -importcert -noprompt -file /usr/share/ca-certificates/mozilla/Starfield_Class_2_CA.crt' \
          '  -alias starfield -keystore default_keystore -storepass changeit'
  not_if '[ -f /tmp/letsencryptaws/default_keystore ]'
end

execute 'generate keystore for specific password' do
  cwd '/tmp/letsencryptaws'
  command 'keytool -importcert -noprompt -file /usr/share/ca-certificates/mozilla/Starfield_Class_2_CA.crt' \
          '  -alias starfield -keystore keystore -storepass somethingelse'
  not_if '[ -f /tmp/letsencryptaws/keystore ]'
end
