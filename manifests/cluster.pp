# cluster.pp
# MariaDB Galera Cluster
# Server application
#
#
# Uses puppetlabs/mysql Module
#   https://github.com/puppetlabs/puppetlabs-mysql
#
# With insights from NeCTAR-RC/mariadb Module
#   https://github.com/NeCTAR-RC/puppet-mariadb
#
# http://dev.mysql.com/doc/refman/5.6/en/adding-users.html
# https://mariadb.com/kb/en/mariadb/mariadb-documentation/mariadb-plugins/pam-authentication-plugin
#
# PLEASE REMEMBER TO SET A PASSWORD FOR THE MySQL root USER !
# To do so, start the server, then issue the following commands:
#
# /usr/bin/mysqladmin -u root password 'new-password'
# /usr/bin/mysqladmin -u root -h mualdrytxx.mcs.miamioh.edu password 'new-password'
#
# Alternatively you can run:
# /usr/bin/mysql_secure_installation
#
# which will also give you the option of removing the test
# databases and anonymous user created by default.  This is
# strongly recommended for production servers.
#
#
# To initialize default mysql db (as root):
#   mysql_install_db --no-defaults --datadir=/srv/mysql_cluster/mysqld_data/
#   mysql_install_db --user=mysql --datadir=/srv/mysql_cluster/mysqld_data
#   THEN
#   ln -s /srv/mysql_cluster/tmp/sockets/mysqld.sock /var/lib/mysql/mysql.sock
#   mysql_secure_installation
#   rm /var/lib/mysql/mysql.sock
#
#

# Install and configure a MariaDB Galera cluster node.
#
# @param manage_user Manage the operating-system mysql user and group.
# @param manage_timezone Load MariaDB time-zone tables.
# @param manage_repo Configure MariaDB and, when required, Percona repositories.
# @param repo_version MariaDB repository major/minor version, such as `10.11`.
# @param dev Install client development headers and bindings.
# @param remove_default_accounts Remove default/anonymous database accounts.
# @param restart Restart the service when managed configuration changes.
# @param service_enabled Whether the MariaDB service is enabled at boot.
# @param service_manage Whether Puppet manages the service resource.
# @param user Operating-system account name.
# @param comment Comment/description for the operating-system account.
# @param uid Numeric UID for the operating-system account.
# @param gid Numeric GID for the operating-system account.
# @param home Home directory for the operating-system account.
# @param shell Login shell for the operating-system account.
# @param group Primary operating-system group name.
# @param groups Supplementary groups for the operating-system account.
# @param config_file Main MariaDB configuration file path.
# @param includedir Configuration include directory, or undef when not used.
# @param config_dir Directory for module-managed configuration snippets.
# @param wsrep_cluster_address Explicit Galera cluster address; overrides peer-derived address.
# @param wsrep_cluster_peers Array of peer addresses or a single peer string used to build gcomm://.
# @param wsrep_cluster_port Galera replication port appended to peer addresses.
# @param wsrep_cluster_name Name shared by all nodes in the Galera cluster.
# @param wsrep_sst_user Database account used for state snapshot transfers.
# @param wsrep_sst_user_peers Hosts from which the SST account may connect.
# @param wsrep_sst_password SST account password. Supply secrets through Hiera or a secret backend.
# @param wsrep_sst_user_tls_options TLS options passed to mysql_user.
# @param wsrep_sst_user_grant_options Grant options passed to mysql_grant.
# @param wsrep_sst_method State snapshot transfer method.
# @param root_password Database root password. Supply secrets through Hiera or a secret backend.
# @param override_options Hash of server options merged with module defaults.
# @param galera_override_options Hash of Galera options merged with module defaults.
# @param auth_pam Enable PAM authentication plugin configuration.
# @param auth_pam_plugin PAM plugin library name.
# @param storeconfigs_enabled Enable exported-resource collection when storeconfigs is configured.
# @param users Hash of mysql users passed to puppetlabs/mysql.
# @param grants Hash of mysql grants passed to puppetlabs/mysql.
# @param databases Hash of databases passed to puppetlabs/mysql.
class mariadb::cluster (
  Boolean $manage_user = $mariadb::params::manage_user,
  Boolean $manage_timezone = $mariadb::params::manage_timezone,
  Boolean $manage_repo          = $mariadb::params::manage_repo,
  Pattern[/^\d+\.?\d*$/] $repo_version = $mariadb::params::repo_version,
  Boolean $dev = true,
  Boolean $remove_default_accounts = $mariadb::params::remove_default_accounts,
  Boolean $restart = false,
  Boolean $service_enabled = true,
  Boolean $service_manage = true,

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
  Optional[String[1]] $wsrep_cluster_address = $mariadb::params::wsrep_cluster_address,
  Variant[Array[String[1]], String[1], Undef] $wsrep_cluster_peers = $mariadb::params::wsrep_cluster_peers,
  String[1] $wsrep_cluster_port = $mariadb::params::wsrep_cluster_port,
  Optional[String[1]] $wsrep_cluster_name = $mariadb::params::wsrep_cluster_name,
  String[1] $wsrep_sst_user = $mariadb::params::wsrep_sst_user,
  Variant[Array[String[1]], String[1]] $wsrep_sst_user_peers = $mariadb::params::wsrep_sst_user_peers,
  String $wsrep_sst_password = $mariadb::params::wsrep_sst_password,
  Optional[Array[String]] $wsrep_sst_user_tls_options = undef,
  Optional[Array[String]] $wsrep_sst_user_grant_options = undef,
  Enum['mariabackup', 'mysqldump', 'rsync', 'rsync_wan', 'xtrabackup', 'xtrabackup-v2'] $wsrep_sst_method = $mariadb::params::wsrep_sst_method, # lint:ignore:140chars
  String $root_password = $mariadb::params::root_password,
  Hash $override_options = {},
  Hash $galera_override_options = {},

  Boolean $auth_pam = $mariadb::params::auth_pam,
  String[1] $auth_pam_plugin = $mariadb::params::auth_pam_plugin,
  Boolean $storeconfigs_enabled = false,

  Hash $users = {},
  Hash $grants = {},
  Hash $databases = {},
) inherits mariadb::params {
  $cluster_options = mysql::normalise_and_deepmerge($mariadb::params::cluster_default_options, $override_options)
  $galera_options  = mysql::normalise_and_deepmerge($mariadb::params::galera_default_options, $galera_override_options)

  anchor { 'mariadb::cluster::start': }
  -> class { 'mariadb::server':
    manage_user          => $manage_user,
    manage_timezone      => $manage_timezone,
    manage_repo          => $manage_repo,
    repo_version         => $repo_version,
    dev                  => $dev,
    cluster              => true,
    restart              => $restart,
    service_enabled      => $service_enabled,
    service_manage       => $service_manage,
    user                 => $user,
    comment              => $comment,
    uid                  => $uid,
    gid                  => $gid,
    home                 => $home,
    shell                => $shell,
    group                => $group,
    groups               => $groups,
    config_file          => $config_file,
    includedir           => $includedir,
    config_dir           => $config_dir,
    root_password        => $root_password,
    auth_pam             => $auth_pam,
    auth_pam_plugin      => $auth_pam_plugin,
    storeconfigs_enabled => $storeconfigs_enabled,
    users                => $users,
    grants               => $grants,
    databases            => $databases,
  }
  -> class { 'mariadb::cluster::auth': }
  -> class { 'mariadb::cluster::galera_config': }
  -> anchor { 'mariadb::cluster::end': }
}
