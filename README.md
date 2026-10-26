mariadb
=============

[![Build Status](https://travis-ci.org/edestecd/puppet-mariadb.svg)](https://travis-ci.org/edestecd/puppet-mariadb)
[![Puppet Forge](https://img.shields.io/puppetforge/v/edestecd/mariadb.svg)](https://forge.puppetlabs.com/edestecd/mariadb)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/edestecd/mariadb.svg)](https://forge.puppetlabs.com/edestecd/mariadb)
[![Puppet Forge Score](https://img.shields.io/puppetforge/f/edestecd/mariadb.svg)](https://forge.puppetlabs.com/edestecd/mariadb/scores)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with mariadb](#setup)
    * [What mariadb affects](#what-mariadb-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with mariadb](#beginning-with-mariadb)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Contributors](#contributors)

## Overview

Puppet Module to install/configure MariaDB client/cluster/server

## Module Description

Uses the [puppetlabs/mysql](https://forge.puppet.com/puppetlabs/mysql) module to provide install/config/service/types/etc management.

This module basically manages the [official mariadb repo](https://downloads.mariadb.org/mariadb/repositories)
and wraps the mysql module with the correct params to switch to the maria packages.  

For the cluster, it also provides management of the wsrep mysql user and galera/wsrep specific config in a separate file.  

Also provided are wsrep var and status facts to monitor your cluster from your fav fact reporter ;)  

The mariadb module provides some classes to install and configure:
* MariaDB Client
* MariaDB Galera Cluster
* MariaDB Server
* MariaDB Repo

## Setup

### What mariadb affects

* mariadb package install
* mariadb config files
* mariadb services
* mariadb user/group (optional)

### Setup Requirements

only need to install the module

### Beginning with mariadb

Minimal mariadb client install for command line use:

```puppet
include mariadb::client
```

## Usage

### Manage the server with pam authentication

```puppet
class { 'mariadb::server':
  auth_pam => true,
}
```

### Also manage the server user and group

```puppet
class { 'mariadb::server':
  manage_user => true,
  uid         => 494,
  gid         => 494,
  shell       => '/sbin/nologin',
}
```

### Customize the cluster config

```puppet
class { 'mariadb::cluster':
  wsrep_cluster_peers     => delete(['192.168.1.1', '192.168.1.2', '192.168.1.3'], $::ipaddress),
  wsrep_cluster_name      => 'my_super_cluster',
  wsrep_sst_password      => 'super_secret_password',
  wsrep_sst_method        => 'xtrabackup-v2',
  root_password           => 'another_secret_password',
  override_options        => {
    'mysqld' => {
      'performance_schema'    => undef,
      'innodb_file_per_table' => 'OFF',
    },
  },
  galera_override_options => {
    'mysqld' => {
      'wsrep_slave_threads'            => '2',
      'innodb_flush_log_at_trx_commit' => '0',
    },
  }
}
```

### Configure with hiera yaml

```puppet
include mariadb::cluster
```
```yaml
---
mariadb::cluster::manage_timezone: true

mariadb::cluster::wsrep_cluster_peers:
- 192.168.1.1
- 192.168.1.2
mariadb::cluster::wsrep_cluster_name: my_super_cluster
mariadb::cluster::wsrep_sst_method: rsync
mariadb::cluster::root_password: another_secret_password

mariadb::cluster::override_options:
  mysqld:
    performance_schema: OFF
    innodb_file_per_table: OFF
mariadb::cluster::galera_override_options:
  mysqld:
    wsrep_slave_threads: 2
    innodb_flush_log_at_trx_commit: 0
```

## Reference

### Classes and parameter reference

The class parameters below are the supported public interface. All configuration option hashes are merged with module defaults; set an option to `undef` where the upstream `puppetlabs/mysql` module supports removing a default.

| Class | Parameter | Default | Description |
|---|---|---|---|
| `mariadb::client` | `manage_repo` | `true` | Manage the MariaDB repository. |
| `mariadb::client` | `repo_version` | `10.10` | MariaDB repository version, for example `10.11`. |
| `mariadb::client` | `dev` | `true` | Install development headers/bindings. |
| `mariadb::client` | `config_dir` | OS-specific | Directory for client configuration. |
| `mariadb::client` | `override_options` | `{}` | Client configuration overrides. |
| `mariadb::server` | `manage_user` | `false` | Manage the operating-system user/group. |
| `mariadb::server` | `manage_timezone` | `false` | Load timezone tables. |
| `mariadb::server` | `manage_repo` | `true` | Manage the MariaDB repository. |
| `mariadb::server` | `repo_version` | `10.10` | MariaDB repository version. |
| `mariadb::server` | `cluster` | `false` | Select cluster package behavior. Normally use `mariadb::cluster` for Galera. |
| `mariadb::server` | `remove_default_accounts` | `true` | Remove default database accounts. |
| `mariadb::server` | `restart` | `true` | Restart after configuration changes. |
| `mariadb::server` | `service_enabled` / `service_manage` | `true` | Control service enablement and management. |
| `mariadb::server` | `service_name` | OS-specific | Service resource name. |
| `mariadb::server` | `user`, `group`, `uid`, `gid`, `home`, `shell`, `comment`, `groups` | OS-specific | Operating-system account settings used when `manage_user` is enabled. |
| `mariadb::server` | `config_file`, `includedir`, `config_dir` | OS-specific | MariaDB configuration paths. |
| `mariadb::server` | `root_password` | `UNSET` | Database root password; set via Hiera/secret backend. Configure explicitly before production use. |
| `mariadb::server` | `auth_pam`, `auth_pam_plugin` | `true`, `auth_pam.so` | Configure PAM authentication. |
| `mariadb::server` | `override_options` | `{}` | Server configuration overrides. |
| `mariadb::server` | `users`, `grants`, `databases` | `{}` | Resources passed to `puppetlabs/mysql`. |
| `mariadb::server` | `storeconfigs_enabled` | `false` | Enable exported-resource collection when storeconfigs is enabled. |
| `mariadb::cluster` | `wsrep_cluster_address` | `undef` | Explicit Galera address; takes precedence over peer list. |
| `mariadb::cluster` | `wsrep_cluster_peers` | `undef` | Peer addresses used to build the `gcomm://` address. |
| `mariadb::cluster` | `wsrep_cluster_port` | `4567` | Galera replication port. |
| `mariadb::cluster` | `wsrep_cluster_name` | `undef` | Shared cluster name. |
| `mariadb::cluster` | `wsrep_sst_user`, `wsrep_sst_user_peers`, `wsrep_sst_password` | `wsrep_sst`, `%`, `UNSET` | SST authentication settings. Set the password securely before enabling SST authentication. |
| `mariadb::cluster` | `wsrep_sst_method` | `mysqldump` | SST method: `mariabackup`, `mysqldump`, `rsync`, `rsync_wan`, `xtrabackup`, or `xtrabackup-v2`. |
| `mariadb::cluster` | `override_options` | `{}` | MariaDB server configuration overrides. |
| `mariadb::cluster` | `galera_override_options` | `{}` | Galera/wsrep configuration overrides. |
| `mariadb::cluster` | `auth_pam`, `auth_pam_plugin` | `true`, `auth_pam.so` | Configure PAM authentication. |
| `mariadb::cluster` | `users`, `grants`, `databases` | `{}` | Resources passed to `puppetlabs/mysql`. |
| `mariadb::cluster` | `storeconfigs_enabled` | `false` | Enable exported-resource collection when storeconfigs is enabled. |
| `mariadb::repo` | `repo_version` | `10.10` | MariaDB repository version. |
| `mariadb::repo` | `percona_repo` | `false` | Also configure the Percona repository. |

Password parameters default to the historical sentinel `UNSET` for compatibility. Production deployments should explicitly set credentials using Hiera eyaml or another secret backend and should not commit plaintext secrets to control repositories.

## Limitations

The module targets Puppet 7 and Puppet 8. The dependency constraints allow stdlib 8 and 9; validate the module against the exact Puppet/stdlib and puppetlabs/mysql versions deployed in your environment.

This module supports modern RedHat and Debian based systems.  
No plans to support other versions (unless you add it :)..

## Development

Pull Requests welcome
