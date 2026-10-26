# server.pp
# MariaDB Server
#
#
# provided by
#
#

# Install and configure a MariaDB server using puppetlabs/mysql.
#
# @param manage_user Manage the operating-system mysql user and group.
# @param manage_timezone Load MariaDB time-zone tables.
# @param manage_repo Configure the MariaDB package repository.
# @param repo_version MariaDB repository major/minor version, such as `10.11`.
# @param dev Install client development headers and bindings.
# @param cluster Select Galera cluster package/configuration behavior.
# @param remove_default_accounts Remove default/anonymous database accounts.
# @param restart Restart the service when managed configuration changes.
# @param service_enabled Whether the MariaDB service is enabled at boot.
# @param service_manage Whether Puppet manages the service resource.
# @param service_name Operating-system service name.
# @param user Operating-system account name; set to undef to skip user management.
# @param comment Comment/description for the operating-system account.
# @param uid Numeric UID for the operating-system account, or undef to use platform defaults.
# @param gid Numeric GID for the operating-system account, or undef to use platform defaults.
# @param home Home directory for the operating-system account.
# @param shell Login shell for the operating-system account.
# @param group Primary group name; set to undef to skip group management.
# @param groups Supplementary groups for the operating-system account.
# @param config_file Main MariaDB configuration file path.
# @param includedir Configuration include directory, or undef when not used.
# @param config_dir Directory for module-managed configuration snippets.
# @param root_password Database root password. Supply a secret through Hiera or a secret backend.
# @param override_options Hash of server configuration options merged with module defaults.
# @param auth_pam Enable PAM authentication plugin configuration.
# @param auth_pam_plugin PAM plugin library name.
# @param storeconfigs_enabled Enable exported-resource collection when storeconfigs is configured.
# @param users Hash of mysql users passed to puppetlabs/mysql.
# @param grants Hash of mysql grants passed to puppetlabs/mysql.
# @param databases Hash of databases passed to puppetlabs/mysql.
class mariadb::server (
  Boolean $manage_user     = $mariadb::params::manage_user,
  Boolean $manage_timezone = $mariadb::params::manage_timezone,
  Boolean $manage_repo     = $mariadb::params::manage_repo,
  Pattern[/^\d+\.?\d*$/] $repo_version = $mariadb::params::repo_version,
  Boolean $dev             = true,
  Boolean $cluster = false,
  Boolean $remove_default_accounts = $mariadb::params::remove_default_accounts,
  Boolean $restart = true,
  Boolean $service_enabled = true,
  Boolean $service_manage = true,
  String[1] $service_name = $mariadb::params::service_name,
  Optional[String[1]] $user = $mariadb::params::user,
  String $comment = $mariadb::params::comment,
  Optional[Integer[1]] $uid = $mariadb::params::uid,
  Optional[Integer[1]] $gid = $mariadb::params::gid,
  Optional[String[1]] $home = $mariadb::params::home,
  Optional[String[1]] $shell = $mariadb::params::shell,
  Optional[String[1]] $group = $mariadb::params::group,
  Optional[Array[String[1]]] $groups = $mariadb::params::groups,
  String[1] $config_file = $mariadb::params::config_file,
  Optional[String] $includedir = $mariadb::params::includedir,
  String[1] $config_dir = $mariadb::params::config_dir,
  String $root_password    = $mariadb::params::root_password,
  Hash $override_options = {},
  Boolean $auth_pam        = $mariadb::params::auth_pam,
  String $auth_pam_plugin  = $mariadb::params::auth_pam_plugin,
  Boolean $storeconfigs_enabled = false,
  Hash $users = {},
  Hash $grants = {},
  Hash $databases = {},
) inherits mariadb::params {
  $options = mysql::normalise_and_deepmerge($mariadb::params::server_default_options, $override_options)

  if $manage_repo {
    class { 'mariadb::repo':
      repo_version => $repo_version,
    }
  }

  if $manage_user {
    Anchor['mariadb::server::start']
    -> class { 'mariadb::server::user': }
    -> Class['mariadb::client::mysql']
  }

  if $manage_timezone {
    Class['mariadb::server::mysql']
    -> class { 'mariadb::server::timezone': }
    -> Anchor['mariadb::server::end']
  }

  anchor { 'mariadb::server::start': }
  -> class { 'mariadb::client::mysql': dev => $dev }
  -> class { 'mariadb::server::mysql': cluster => $cluster }
  -> anchor { 'mariadb::server::end': }

  if $settings::storeconfigs and $storeconfigs_enabled {
    Mysql::Db <<| tag == $facts['networking']['domain'] |>> {
      require => Anchor['mariadb::server::end'],
    }
    -> Mariadb::Db_grant <<| tag == $facts['networking']['domain'] |>> {
      require => Anchor['mariadb::server::end'],
    }
  }
}
