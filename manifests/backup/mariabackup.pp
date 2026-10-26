# mariadb::backup::mariabackup
#
# Manage MariaDB mariabackup Backup
#
# @summary Manage MariaDB mariabackup Backup
#
# @example
#   include mariadb::backup::mariabackup

# Configure scheduled MariaDB physical backups using mariabackup.
#
# @param mariabackup_package_name Package providing the mariabackup executable.
# @param backupuser Database account used by the backup command, if required.
# @param backuppassword Password for the backup account; use a secret backend.
# @param backupdir Destination directory for backup files.
# @param backupmethod Backup mode passed to the script.
# @param backupdirmode Permissions for the backup directory.
# @param backupdirowner Owner of the backup directory.
# @param backupdirgroup Group of the backup directory.
# @param backupcompress Whether to compress backup output.
# @param backupdatabases Optional list of databases to back up.
# @param ensure Whether the scheduled backup is present or absent.
# @param time Cron hour and minute values.
# @param prescript Optional command to run before backup.
# @param postscript Optional command to run after backup.
# @param execpath PATH used by scheduled backup commands.
# @param optional_args Additional command-line arguments.
# @param additional_cron_args Additional text appended to the cron command.
# @param incremental Enable incremental backup behavior.
# @param logging_enabled Redirect output to a log file.
# @param log_path Directory containing the log file.
# @param log_file Log filename.
class mariadb::backup::mariabackup (
  String[1] $mariabackup_package_name = $mariadb::params::backup_package_name,
  Optional[String[1]] $backupuser = undef,
  Optional[String] $backuppassword = undef,
  String[1] $backupdir = $mariadb::params::backupdir,
  String[1] $backupmethod = 'mariabackup',
  String[1] $backupdirmode = '0700',
  String[1] $backupdirowner = 'root',
  String[1] $backupdirgroup = 'root',
  Boolean $backupcompress = true,
  Array[String[1]] $backupdatabases = [],
  Enum['present', 'absent'] $ensure = 'present',
  Tuple[Variant[String, Integer], Variant[String, Integer]] $time = ['23', '5'],
  Variant[Boolean, String, Array[String]] $prescript = false,
  Variant[Boolean, String, Array[String]] $postscript = false,
  String[1] $execpath = '/usr/bin:/usr/sbin:/bin:/sbin',
  Array $optional_args = [],
  String $additional_cron_args = '', # lint:ignore:empty_string_assignment
  Boolean $incremental = true,
  Boolean $logging_enabled = false,
  String[1] $log_path = $mariadb::params::home,
  String[1] $log_file = 'mariabackup.log'
) inherits mariadb::params {
  ensure_packages($mariabackup_package_name)

  $_redirect = $logging_enabled ? {
    true    => ">>${log_path}/${log_file} 2>&1",
    default => undef,
  }

  if $backupuser and $backuppassword {
    mysql_user { "${backupuser}@localhost":
      ensure        => $ensure,
      password_hash => mysql::password($backuppassword),
      require       => Class['mysql::server::root_password'],
    }

    mysql_grant { "${backupuser}@localhost/*.*":
      ensure     => $ensure,
      user       => "${backupuser}@localhost",
      table      => '*.*',
      privileges => ['RELOAD', 'PROCESS', 'LOCK TABLES', 'REPLICATION CLIENT'],
      require    => Mysql_user["${backupuser}@localhost"],
    }
  }

  cron { 'mariabackup':
    ensure  => $ensure,
    command => "/usr/local/sbin/mariabackup.sh ${additional_cron_args}${_redirect}",
    user    => 'root',
    hour    => $time[0],
    minute  => $time[1],
    weekday => '0-6',
    require => Package[$mariabackup_package_name],
  }

  file { 'mysqlbackupdir':
    ensure => 'directory',
    path   => $backupdir,
    mode   => $backupdirmode,
    owner  => $backupdirowner,
    group  => $backupdirgroup,
  }

  file { 'mariabackup.sh':
    ensure  => $ensure,
    path    => '/usr/local/sbin/mariabackup.sh',
    mode    => '0700',
    owner   => 'root',
    group   => 'root',
    content => template('mariadb/backup/mariabackup.sh.erb'),
  }
}
