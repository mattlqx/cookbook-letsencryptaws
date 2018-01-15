#!/usr/bin/ruby
# frozen_string_literal: true

# This script is used by the certbot ACME client for Let's Encrypt
# to create DNS records used by the CA to verify domain ownership.

require_relative 'dnschange'

unless ENV.key?('CERTBOT_DOMAIN') && ENV.key?('CERTBOT_VALIDATION')
  puts 'Set CERTBOT_DOMAIN and CERTBOT_VALIDATION environment variables.'
  exit
end

puts CertBot::DNSChange.do_change(
  'DELETE',
  ENV['CERTBOT_DOMAIN'],
  ENV['CERTBOT_VALIDATION']
)
