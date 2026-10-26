# mariadb::backup::mysqldump
#
# Manage MariaDB Galera Cluster Backup
#
# @summary Manage MariaDB Galera Cluster Backup
#
# @example
#   include mariadb::backup::mysqldump
# Configure scheduled logical backups using mysqldump.
#
# @param backupuser Database account used by mysqldump.
# @param backuppassword Password for the backup account; use a secret backend.
# @param backupdir Destination directory for dump files.
# @param maxallowedpacket Maximum packet size passed to mysqldump.
# @param backupdirmode Permissions for the backup directory.
# @param backupdirowner Owner of the backup directory.
# @param backupdirgroup Group of the backup directory.
# @param backupcompress Whether to compress dump output.
# @param backuprotate Number of backups to retain.
# @param initiator_node Whether this node initiates the backup schedule.
# @param ignore_events Ignore changes to selected resources when scheduling.
# @param delete_before_dump Remove old dump files before creating new ones.
# @param backupdatabases List of databases to back up.
# @param file_per_database Write a separate dump file per database.
# @param include_triggers Include triggers in the dump.
# @param include_routines Include stored procedures and functions.
# @param ensure Whether the scheduled backup is present or absent.
# @param time Cron hour and minute values.
# @param prescript Optional command to run before backup.
# @param postscript Optional command to run after backup.
# @param execpath PATH used by scheduled backup commands.
# @param optional_args Additional command-line arguments.
class mariadb::backup::mysqldump (
  String $backupuser = '', # lint:ignore:empty_string_assignment
  String $backuppassword = '', # lint:ignore:empty_string_assignment
  String $backupdir = '', # lint:ignore:empty_string_assignment
  String[1] $maxallowedpacket = '1M',
  String[1] $backupdirmode = '0700',
  String[1] $backupdirowner = $mariadb::params::user,
  String[1] $backupdirgroup = $mariadb::params::group,
  Boolean $backupcompress = true,
  Integer[0] $backuprotate = 30,
  Boolean $initiator_node = false,
  Boolean $ignore_events = true,
  Boolean $delete_before_dump = false,
  Array[String[1]] $backupdatabases = [],
  Boolean $file_per_database = false,
  Boolean $include_triggers = false,
  Boolean $include_routines = false,
  Enum['present', 'absent'] $ensure = 'present',
  Tuple[Variant[String, Integer], Variant[String, Integer]] $time = ['23', '5'],
  Variant[Boolean, String, Array[String]] $prescript = false,
  Variant[Boolean, String, Array[String]] $postscript = false,
  String[1] $execpath = '/usr/bin:/usr/sbin:/bin:/sbin',
  Array $optional_args = [],
) inherits mariadb::params {
  include mariadb::cluster

  if $backupcompress {
    ensure_packages(['bzip2'])
    Package['bzip2'] -> File['wsrep_sst_backup']
  }

  $initiator_ensure = $initiator_node ? {
    true    => $ensure,
    default => 'absent',
  }

  $galera_options = $mariadb::cluster::galera_config::options['mysqld']

  mysql_user { "${backupuser}@localhost":
    ensure        => $ensure,
    password_hash => mysql::password($backuppassword),
    require       => Class['mysql::server::root_password'],
  }

  if $include_triggers {
    $privs = ['SELECT', 'RELOAD', 'LOCK TABLES', 'SHOW VIEW', 'PROCESS', 'TRIGGER']
  } else {
    $privs = ['SELECT', 'RELOAD', 'LOCK TABLES', 'SHOW VIEW', 'PROCESS']
  }

  mysql_grant { "${backupuser}@localhost/*.*":
    ensure     => $ensure,
    user       => "${backupuser}@localhost",
    table      => '*.*',
    privileges => $privs,
    require    => Mysql_user["${backupuser}@localhost"],
  }

  $wsrep_provider_options = $galera_options['wsrep_provider_options'] ? {
    undef   => undef,
    default => ";${galera_options['wsrep_provider_options']}",
  }

  # lint:ignore:strict_indent
  $garbd_conf = @("END"/L)
    address = ${galera_options['wsrep_cluster_address']}
    group = ${mariadb::cluster::wsrep_cluster_name}
    options = gmcast.listen_addr=tcp://0.0.0.0:4444${wsrep_provider_options}
    sst = backup
    log = /var/log/garbd.log
    | END
  # lint:endignore

  file { 'garbd.conf':
    ensure  => $ensure,
    path    => '/etc/garbd.conf',
    mode    => '0700',
    owner   => 'root',
    group   => $mysql::params::root_group,
    content => $garbd_conf.delete("'"),
  }

  cron { 'mysql-backup':
    ensure  => $initiator_ensure,
    command => 'garbd --cfg /etc/garbd.conf',
    user    => 'root',
    hour    => $time[0],
    minute  => $time[1],
    require => File['wsrep_sst_backup', 'garbd.conf'],
  }

  file { 'wsrep_sst_backup':
    ensure  => $ensure,
    path    => '/bin/wsrep_sst_backup',
    mode    => '0700',
    owner   => $backupdirowner,
    group   => $backupdirgroup,
    content => template('mysql/mysqlbackup.sh.erb'),
  }

  file { 'mysqlbackupdir':
    ensure => 'directory',
    path   => $backupdir,
    mode   => $backupdirmode,
    owner  => $backupdirowner,
    group  => $backupdirgroup,
  }
}
