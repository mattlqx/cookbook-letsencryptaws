# letsencryptaws CHANGELOG

This file is used to list changes made in each version of the letsencryptaws cookbook.

## 2.0.7
- [mattlqx] - allow `node['letsencryptaws']['ebs_device']` to be nil to prevent mkfs, mount and check.

## 2.0.5
- [mattlqx] - version bumps for certbot and cryptography

## 2.0.4
- [Akinari1087] - add aws_session_token to s3 resources

## 2.0.3
- [mattlqx] - prevent group resource from clobbering members

## 2.0.2
- [mattlqx] - change method name from `creds` to `aws_creds` to not conflict with remote_file_s3.

## 2.0.1
- [mattlqx] - lazy evaluate credentials

## 2.0.0
- [mattlqx] - Switch from poise-python to pyenv cookbooks for Python management. 😔
- [mattlqx] - Change `node['letsencryptaws']['blacklist']` to `node['letsencryptaws']['blocklist']`.
- [mattlqx] - Change `node.run_state['creds']` to `node.run_state['letsencryptaws_creds']` to optionally use in place of data bag.
- [mattlqx] - Support Ubuntu 20.04 and Python 3.
- [mattlqx] - Force `parsedatetime` version to 2.5 with Python 2.
- [mattlqx] - Use new ChefSpec syntax.

## 1.1.4
- [mattlqx] - Bump certbot and cryptography version.
- [mattlqx] - Use enova version of poise-python. See [Berksfile](Berksfile) for how to source this in your environment.

## 1.1.3
- [mattlqx] - Ignore READMEs in syncing to s3.

## 1.1.1
- [mattlqx] - Bump cryptography version to 2.5.
- [mattlqx] - Pin pip version to 18.0 to prevent poise-python bug.

## 1.1.0
- [mattlqx] - Allow certbot version to be specified and upgraded.
- [mattlqx] - Ditch custom Ruby for Route 53 authentication in favor of certbot-dns-route53.
- [mattlqx] - Wildcard certificate support.

## 1.0.8
- [mattlqx] - Add explicit python package version idna 2.6. Yay constaints.

## 1.0.7
- [mattlqx] - Bump `cryptography` module version.

## 1.0.6
- [mattlqx] - Loosen poise-python version dependency.

## 1.0.5
- [mattlqx] - Switch backend s3 resource to `remote_file_s3`

## 1.0.4
- [mattlqx] - Use `--cert-name` attribute for certbot.

## 1.0.3
- [mattlqx] - Add attribute for root CA path.

## 1.0.2
- [mattlqx] - Correct `sync_path` default to match documentation.

## 1.0.1
- [mattlqx] - Bug fixes and additional docs.

## 1.0.0
- [mattlqx] - Sanitize and open-source. Initial public release. 🎉

## 0.4.0
- [mattlqx] - Add recipe to import .p12s into arbitrary keystores.

## 0.3.0
- [mattlqx] - Bump cryptography version.
- [mattlqx] - Generate PKCS12 keystore for downloaded certificates.

## 0.2.8
- [mattlqx] - Fix to prevent duplicate certs from being deleted.
- [mattlqx] - Add blacklist attribute to prevent certs from being requested.

## 0.1.0
- [mattlqx] - Initial release of letsencryptaws

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.
