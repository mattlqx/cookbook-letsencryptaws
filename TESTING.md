## Testing

### Test Kitchen

Setup a .kitchen.local.yml with a `node['letsencryptaws']['certs']` hash that will request a test certificate under a domain in which you control. `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables can be used to control AWS credentials being used within the Chef run. See .kitchen.yml for an example.

### RSpec

Rspec/ChefSpec unit tests can be run by simply running `rspec`.
