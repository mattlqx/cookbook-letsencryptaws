# frozen_string_literal: true

def creds(key) # rubocop:disable Metrics/AbcSize
  begin
    node.run_state['creds'] ||= \
      data_bag_item(node['letsencryptaws']['data_bag'], node['letsencryptaws']['data_bag_item']).to_hash
  rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagName
    node.run_state['creds'] = {}
  end
  node.run_state['creds'].fetch(key, nil)
end
