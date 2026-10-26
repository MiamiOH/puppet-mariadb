# See README.md for details.
# Manage a database grant through puppetlabs/mysql.
#
# @param user Database username receiving the grant.
# @param dbname Database name; defaults to the defined resource title.
# @param host Host from which the account may connect.
# @param grant Privileges to grant, for example `ALL` or an array of privileges.
# @param options Additional grant options accepted by puppetlabs/mysql.
# @param ensure Whether the grant is present or absent.
define mariadb::db_grant (
  String[1] $user,
  String[1] $dbname = $name,
  String[1] $host = 'localhost',
  Variant[String[1], Array[String[1]]] $grant = 'ALL',
  Optional[Hash] $options = undef,
  Enum['present', 'absent'] $ensure = 'present',
) {
  $table = "${dbname}.*"

  include mysql::client

  $grant_resource = {
    ensure     => $ensure,
    privileges => $grant,
    provider   => 'mysql',
    user       => "${user}@${host}",
    table      => $table,
    # options    => $options,
    require    => Class['mysql::server'],
  }
  ensure_resource('mysql_grant', "${user}@${host}/${table}", $grant_resource)
}
