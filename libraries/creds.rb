# frozen_string_literal: true

require 'json'

def aws_creds(key) # rubocop:disable Metrics/AbcSize
  begin
    node.run_state['letsencryptaws_creds'] ||= \
      if File.exist?(node['letsencryptaws']['aws_credentials_file'])
        JSON.parse(IO.read(node['letsencryptaws']['aws_credentials_file']))
      else
        data_bag_item(node['letsencryptaws']['data_bag'], node['letsencryptaws']['data_bag_item']).to_hash
      end
  rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagName
    node.run_state['letsencryptaws_creds'] = {}
  end
  node.run_state['letsencryptaws_creds'].fetch(key, nil)
end
