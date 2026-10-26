# repo.pp
# Manage the percona repo.
#

class mariadb::repo::percona {
  case $facts['os']['family'] {
    'RedHat': {
      anchor { 'mariadb::repo::percona::start': }
      -> class { 'mariadb::repo::percona::yum': }
      -> anchor { 'mariadb::repo::percona::end': }
    }
    'Debian': {
      class { 'mariadb::repo::percona::apt': }
    }
    default: {
      fail("Unsupported managed repository for ${facts['os']['family']}, currently only supports RedHat and Debian")
    }
  }
}
