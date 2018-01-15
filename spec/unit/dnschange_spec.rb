# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'
require './files/default/dnschange'

describe CertBot::DNSChange do
  let(:route53_client) { double('route53') }
  let(:hosted_zones_obj) { double('hosted_zones') }
  let(:hosted_zones_data) { [OpenStruct.new(id: 'hostedzone/ABCD1234', name: 'example.com')] }
  let(:change_rr_data) { OpenStruct.new(change_info: OpenStruct.new(id: 'changeid', status: 'INSYNC')) }
  let(:change_rr_pending) { OpenStruct.new(change_info: OpenStruct.new(id: 'changeid', status: 'PENDING')) }

  before do
    allow(Aws::Route53::Client).to receive(:new).and_return(route53_client)
    allow(route53_client).to receive(:list_hosted_zones_by_name).and_return(hosted_zones_obj)
    allow(route53_client).to receive(:change_resource_record_sets).and_return(change_rr_data)
    allow(route53_client).to receive(:get_change).and_return(change_rr_pending, change_rr_data)
    allow(hosted_zones_obj).to receive(:hosted_zones).and_return(hosted_zones_data)
    allow(described_class).to receive(:sleep).and_return(nil)
  end

  describe '.do_change' do
    let(:change_id) { described_class.do_change('UPSERT', 'test.example.com', 'abc123') }

    before do
      described_class.do_change('UPSERT', 'test.example.com', 'abc123')
    end

    it 'searches for zone id' do
      expect(route53_client).to have_received(:list_hosted_zones_by_name).with(dns_name: 'example.com').once
    end

    it 'requests record set change' do
      expect(route53_client).to have_received(:change_resource_record_sets).with(
        change_batch: {
          changes: [{
            action: 'UPSERT',
            resource_record_set: {
              name: '_acme-challenge.test.example.com',
              type: 'TXT',
              ttl: 60,
              resource_records: [
                { value: '"abc123"' }
              ]
            }
          }],
          comment: 'automated certbot update',
        },
        hosted_zone_id: 'ABCD1234'
      ).once
    end

    it 'returns the change id' do
      expect(change_id).to eq('changeid')
    end
  end
end
