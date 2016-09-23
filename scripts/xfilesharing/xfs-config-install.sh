#!/bin/bash

eecho () {
    echo -e "\e[1;32mXfileSharing installation script:\033[0m $1"
}

# setting the initial environment

echo -e "Enter server number (for serv10 enter simply just 10): \c"
read SRV
echo -e "Enter email address for monitoring: \c"
read EML

hostname serv$SRV.rainy.la
hash -r

MAIN_IP=`ifconfig | grep inet | cut -d ":" -f2 | cut -d " " -f1 | grep -v 127.0.0.1 | awk 'NF'`
echo "$MAIN_IP serv$SRV.rainy.la serv$SRV" >> /etc/hosts

# move to /root folder
cd /root

# disable selinux
setenforce 0
echo "selinux=disabled" > /etc/sysconfig/selinux

# disable standard centos firewall
service iptables stop
service ip6tables stop
chkconfig iptables off
chkconfig ip6tables off

# disable ipv6
echo "NETWORKING_IPV6=no" >> /etc/sysconfig/network
echo "IPV6INIT=no" >> /etc/sysconfig/network
echo "IPV6INIT=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0

echo >> /etc/sysctl.conf
echo "#disable ipv6" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf

# install additional centos repos (rpmforge, epel, remi)
if [ $(rpm -qa|grep -c rpmforge) -gt 0 ]; then
    echo "RPMFORGE repo installed, skipping..."
else
    wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
    rpm -Uhv rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
    rm -f rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
fi

if [ $(rpm -qa|grep -c rpmforge) -gt 0 ]; then
    echo "EPEL repo installed, skipping..."
else
    wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
    rpm -Uhv epel-release-latest-6.noarch.rpm
    rm -f epel-release-latest-6.noarch.rpm
fi

if [ $(rpm -qa|grep -c rpmforge) -gt 0 ]; then
    echo "REMI repo installed, skipping..."
else
    wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
    rpm -Uhv remi-release-6.rpm
    rm -f remi-release-6.rpm
fi

# enable remi repo
sed -i '9s/enabled=0/enabled=1/' /etc/yum.repos.d/remi.repo

# update everything
yum -y update

# install other packages
yum -y install htop vim tcpdump mlocate bind-utils nload nethogs mtr mytop iftop iotop mailx alpine telnet mc lynx elinks git perl-libwww-perl.noarch perl-DBI perl-DBD-MySQL perl-GD mc tcpdump unzip perl-JSON.noarch perl-JSON-Any.x86_64 json-c.x86_64 perl-Test-JSON.noarch

yum -y install httpd httpd-devel httpd-tools mod_perl mod_ssl mod_wsgi
yum -y install glibc glibc-headers kernel-devel kernel-headers make automake autoconf cpp gcc
yum -y install gd-progs.x86_64 perl-GDGraph.noarch gdisk.x86_64 gd.x86_64 unzip bind-utils tcpdump rpm-build
yum -y install pcre pcre-devel perl-ExtUtils-Embed.x86_64 openssh-clients
yum -y install zlib zlib-devel openssl openssl-devel

mkdir -p /home/xfs
wget http://club3d.ro/xfilesharingpro.zip
unzip xfilesharingpro.zip
mkdir -p /home/serv$SRV
mkdir -p /home/serv$SRV/serv$SRV.rainy.la
mkdir -p /home/serv$SRV/serv$SRV.rainy.la/html
cd fs-dist
cp -r cgi-bin /home/serv$SRV/serv$SRV.rainy.la
cp -r htdocs/* /home/serv$SRV/serv$SRV.rainy.la/html/
chown apache:apache /home/serv$SRV -R

# install additional perl modules
yum -y install perl perl-Archive-Tar perl-Compress-Raw-Bzip2 perl-libxml-perl perl-Test-Harness perl-Module-Build perl-XML-Dumper perl-Pod-Escapes perl-Locale-Maketext-Simple perl-Compress-Raw-Zlib perl-Digest-SHA perl-CGI perl-DBIx-Simple perl-ExtUtils-ParseXS perl-Test-Simple perl-Git perl-BSD-Resource mod_perl perl-XML-Twig perl-DBD-MySQL perl-Module-Pluggable perl-URI perl-Log-Message perl-Package-Constants perl-Compress-Zlib perl-Term-UI perl-Object-Accessor perl-Module-Loaded perl-parent perl-Time-HiRes perl-libwww-perl perl-devel perl-Archive-Extract perl-ExtUtils-Embed perl-Newt perl-Crypt-SSLeay perl-XML-Grove perl-libs perl-Module-Load-Conditional perl-IO-Compress-Zlib perl-Log-Message-Simple perl-Module-CoreList perl-IO-Compress-Bzip2 perl-Time-Piece perl-HTML-Parser perl-ExtUtils-MakeMaker perl-File-Fetch perl-CPANPLUS perl-core perl-Pod-Simple perl-Params-Check perl-Module-Load perl-Parse-CPAN-Meta perl-DBD-SQLite perl-HTML-Tagset perl-IPC-Cmd perl-CPAN perl-Error perl-GD perl-version perl-DBI perl-IO-Compress-Base perl-IO-Zlib perl-XML-Parser perl-ExtUtils-CBuilder

# install NGINX
wget http://nginx.org/download/nginx-1.9.7.tar.gz
tar zxvf nginx-1.9.7.tar.gz
cd nginx-1.9.7
./configure --prefix=/usr/local/nginx/ --with-http_stub_status_module --with-http_perl_module --with-http_flv_module --with-http_mp4_module --with-http_realip_module
make
make install
cd /usr/local/
wget http://club3d.ro/nginx.tgz
tar zxvf nginx.tgz
chown apache:apache nginx/ -R
cd nginx
cp nginx-init /etc/init.d/nginx
chmod 755 /etc/init.d/nginx
chkconfig nginx on
cd conf
sed -i 's/nobody/apache/g' nginx.conf
sed -i "s/serv8/serv$SRV/g" nginx.conf

cat >> /etc/httpd/conf/httpd.conf << EOF
NameVirtualHost $MAIN_IP
<VirtualHost serv$SRV.rainy.la>
DocumentRoot /home/serv$SRV/serv$SRV.rainy.la/html
<Directory "/home/serv$SRV/serv$SRV.rainy.la/html">
allow from all
Options +Indexes
Options +ExecCGI
AddHandler cgi-script .cgi .pl
</Directory>

ScriptAlias /cgi-bin/ "/home/serv$SRV/serv$SRV.rainy.la/cgi-bin/"
Options +ExecCGI
</VirtualHost>
EOF

# restart apache
service httpd restart

# adding crontab
#echo "* * * * *     cd /home/serv$SRV/serv$SRV.rainy.la/cgi-bin;./transfer.pl >/dev/null 2>&1" >> /var/spool/cron/root
service crond restart

# make the installer cgi script executable
chmod +x /home/serv$SRV/serv$SRV.rainy.la/cgi-bin/install_fs.cgi

# create simple script for service monitoring (httpd, nginx)
FILE="/root/xfsmon.pl"

if [ -f $FILE ];
then
   echo "Monitoring script $FILE exists"
else
   echo "Monitoring script $FILE does not exist!"

echo -e "Enter monitoring email address for notifications: \c"

cat > /root/xfsmon.pl << 'EOF'
#!/usr/bin/perl
use strict;

my @services = ('httpd', 'nginx');
my $alert_email = '$EML';
my $host = `/bin/hostname`;
chomp $host;

foreach my $service (@services) {
	my $status = `/bin/ps cax | /bin/grep $service`;
	if (!$status) {
		my $alert = `/bin/mailx -s "ALERT! $host: $service stopped" $alert_email < /dev/null > /dev/null`;
		print "ALERT! $host: $service not running\n";
		print "Trying to start service: $service\n";
		system "/etc/init.d/$service start";
	}
}
EOF

echo -n "Service Monitoring CRON"
echo 
if grep -q xfs /var/spool/cron/root ; then 
    echo "cron entry already exists, skipping to the next step..."; 
else 
    echo "cron entry not found, adding it..."; 
fi

echo "*/1 * * * * /usr/bin/perl /root/xfsmon.pl" >> /var/spool/cron/root

fi

echo ""
echo "Please point your browser to http://serv$SRV.rainy.la/cgi-bin/install_fs.cgi in order to install the file server"
echo "DONE"
