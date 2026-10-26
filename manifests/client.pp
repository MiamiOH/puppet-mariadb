# client.pp
# MariaDB
# Client application
# Optional Development libs and headers
#
#
# gives you the mysql terminal etc...
#
# Gives you libs and headers to compile mysql clients...
# For example, these are required to build/install
# the ruby gems mysql and mysql2
#
#

# Manage MariaDB client packages and client configuration.
#
# @param manage_repo Whether to configure the official MariaDB package repository.
# @param repo_version MariaDB repository major/minor version, such as `10.11`.
# @param dev Whether to install development headers and client bindings.
# @param config_dir Absolute directory in which client configuration is written.
# @param override_options Hash of MySQL client configuration options merged with module defaults.
class mariadb::client (
  Boolean $manage_repo = $mariadb::params::manage_repo,
  Pattern[/^\d+\.?\d*$/] $repo_version = $mariadb::params::repo_version,
  Boolean $dev = true,
  String[1] $config_dir = $mariadb::params::config_dir,
  Hash $override_options = {},
) inherits mariadb::params {
  $options = mysql::normalise_and_deepmerge($mariadb::params::client_default_options, $override_options)

  if $manage_repo {
    class { 'mariadb::repo':
      repo_version => $repo_version,
    }
  }

  anchor { 'mariadb::client::start': }
  -> class { 'mariadb::client::mysql': }
  -> class { 'mariadb::client::config': }
  -> anchor { 'mariadb::client::end': }
}
