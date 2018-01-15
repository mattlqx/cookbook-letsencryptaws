# frozen_string_literal: true

module CertBot
  # This class is used by Let's Encrypt to request a DNS record change in order for control validation
  class DNSChange
    require 'timeout'
    require 'aws-sdk-route53'

    def self.do_change(type, dnsname, validation, timeout: 300)
      @route53 = Aws::Route53::Client.new(region: 'us-west-2')
      zone_id = @route53.list_hosted_zones_by_name(dns_name: dnsname.split('.')[-2..-1].join('.')) \
                        .hosted_zones.first.id

      change_resp = @route53.change_resource_record_sets(
        change_batch: {
          changes: [
            {
              action: type,
              resource_record_set: {
                name: "_acme-challenge.#{dnsname}",
                type: 'TXT',
                ttl: 60,
                resource_records: [
                  { value: "\"#{validation}\"" }
                ]
              }
            }
          ],
          comment: 'automated certbot update'
        },
        hosted_zone_id: zone_id.split('/').last
      )

      wait_for_change(change_resp.change_info.id, timeout)
    end

    def self.wait_for_change(change_id, timeout)
      change_resp = @route53.get_change(id: change_id)
      Timeout.timeout(timeout) do
        until change_resp.change_info.status == 'INSYNC'
          sleep 10
          change_resp = @route53.get_change(id: change_id)
        end
      end
      change_id
    end
  end
end
