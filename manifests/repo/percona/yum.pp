# yum.pp
# Manage the percona yum repo.
#

class mariadb::repo::percona::yum {
  yumrepo { 'percona-release':
    baseurl  => "http://repo.percona.com/release/${facts['os']['release']['major']}/RPMS/${facts['os']['architecture']}",
    descr    => 'Percona-Release',
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => 'https://www.percona.com/downloads/RPM-GPG-KEY-percona',
  }
  Yumrepo['percona-release'] -> Package<| tag == 'percona' |>
}
