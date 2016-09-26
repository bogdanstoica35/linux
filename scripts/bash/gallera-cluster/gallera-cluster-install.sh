#!/bin/bash

# the script needs some modifications and it's created for CentOS 7


echo "Set a default mysql root password. Enter password: \c"
read SQLROOTPASSWD
echo "Enter sync cluster user: \c"
read CLUSTERUSER
echo "Enter sync cluster password: \c"
read CLUSTERPASS
echo "Enter server hostname: \c"
read SRVHOST
echo "Enter server ip: \c"
read SRVIP

# erase previous mysql versions
yum erase mysql-server mysql mysql-client mysql-devel
rm -rf /var/lib/mysql

# kill mysql
sudo kill -9 `pidof mysqld`

# add MariaDB repo to yum repo lists
cat > /etc/yum.repos.d/MariaDB.repo <<EOF
# MariaDB 10.0 CentOS repository list - created 2015-07-09 14:56 UTC
# http://mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.0/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

# install socat & Mysql Galerra server for clustering
yum install MariaDB-Galera-server MariaDB-client rsync galera socat


# start mysql service
service mysql start

# do a initial mysql config
mysql_secure_installation

mysql -u root -p -e "GRANT ALL PRIVILEGES ON *.* TO 'cluster'@'%' IDENTIFIED BY 'cluster123' WITH GRANT OPTION;"

cat > /etc/my.cnf.d/server.cnf <<EOF
#
# These groups are read by MariaDB server.
# Use it for options that only the server (but not clients) should see
#
# See the examples of server my.cnf files in /usr/share/mysql/
#

# this is read by the standalone daemon and embedded servers
[server]

# this is only for the mysqld standalone daemon
[mysqld]

#
# * Galera-related settings
#
[galera]
binlog_format=ROW
default_storage_engine=innodb
innodb_autoinc_lock_mode=2
innodb_locks_unsafe_for_binlog=1
query_cache_size=0
query_cache_type=0
bind-address=0.0.0.0
datadir=/var/lib/mysql
innodb_log_file_size=100M
innodb_file_per_table
innodb_flush_log_at_trx_commit=2

# this is only for embedded server
[embedded]

# This group is only read by MariaDB servers, not by MySQL.
[mariadb]
#binlog_format=ROW
#default_storage_engine=innodb
#innodb_autoinc_lock_mode=2
#innodb_locks_unsafe_for_binlog=1
#query_cache_size=0
#query_cache_type=0
#bind-address=0.0.0.0
#datadir=/var/lib/mysql
#innodb_log_file_size=100M
#innodb_file_per_table
#innodb_flush_log_at_trx_commit=2
#
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
wsrep_cluster_address="gcomm://192.168.22.15,192.168.22.16,192.168.22.17,192.168.22.18"
wsrep_cluster_name='mgm-hongkong'
wsrep_node_address='192.168.22.15'
wsrep_node_name='s11.c2.hk.onem'
wsrep_sst_method=rsync
wsrep_sst_auth=cluster:cluster123

# This group is only read by MariaDB-10.0 servers.
[mariadb-10.0]
EOF
