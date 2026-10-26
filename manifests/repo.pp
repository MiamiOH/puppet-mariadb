# repo.pp
# Manage the mariadb repo.
#

# Configure the official MariaDB package repository.
#
# @param repo_version MariaDB repository major/minor version, such as `10.11`.
# @param percona_repo Also configure the Percona repository for SST tools.
class mariadb::repo (
  Pattern[/^\d+\.?\d*$/] $repo_version = $mariadb::params::repo_version,
  Boolean $percona_repo = false,
) inherits mariadb::params {
  $os = $facts['os']['name'] ? {
    'RedHat'      => 'rhel',
    'CentOS'      => 'centos',
    'Fedora'      => 'fedora',
    'Debian'      => 'debian',
    'OracleLinux' => 'rhel',
    'Ubuntu'      => 'ubuntu',
    'Rocky'       => 'rhel',
    'AlmaLinux'   => 'rhel',
  }
  $arch = $facts['os']['architecture'] ? {
    'i386'   => 'x86',
    'x86_64' => 'amd64',
    default  => $facts['os']['architecture'],
  }

  case $facts['os']['family'] {
    'RedHat': {
      include mariadb::repo::yum
    }
    'Debian': {
      include mariadb::repo::apt
    }
    default: {
      fail("Unsupported managed repository for ${facts['os']['family']}, currently only supports RedHat and Debian")
    }
  }

  if $percona_repo {
    include mariadb::repo::percona
  }
}
