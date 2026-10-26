# wsrep_sst_user.pp
# Manage one wsrep_sst_auth user.
# This user is used to sync between cluster nodes and thus needs root like access to everything.
#
# Manage a Galera state snapshot transfer database account.
#
# @param wsrep_sst_password Password for the SST account; use a secret backend.
# @param wsrep_sst_user Database account name (defaults to the defined resource title).
# @param wsrep_sst_user_tls_options TLS options passed to puppetlabs/mysql.
# @param wsrep_sst_user_grant_options Grant options passed to puppetlabs/mysql.

define mariadb::cluster::wsrep_sst_user (
  String $wsrep_sst_password,
  String[1] $wsrep_sst_user = $name,
  Optional[Hash] $wsrep_sst_user_tls_options = undef,
  Optional[Hash] $wsrep_sst_user_grant_options = undef,
) {
  mysql_user { $wsrep_sst_user:
    ensure        => present,
    password_hash => mysql::password($wsrep_sst_password),
    tls_options   => $wsrep_sst_user_tls_options,
    require       => Class['mysql::server::root_password'],
  }

  mysql_grant { "${wsrep_sst_user}/*.*":
    ensure     => present,
    user       => $wsrep_sst_user,
    table      => '*.*',
    privileges => ['ALL'],
    options    => $wsrep_sst_user_grant_options,
    require    => Mysql_user[$wsrep_sst_user],
  }
}
