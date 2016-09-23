#!/usr/bin/perl

use strict;
use warnings;
use MIME::Lite;
use Mail::Mailer;
use Unix::Syslog qw(:subs);
use Unix::Syslog qw(:macros);
use Getopt::Std;
use Sys::Hostname;
use POSIX qw(setuid setgid);
use English;

#define email address
my $email = 'bogdan@vrem.ro';

my @services = ('mysql', 'nginx', 'php-fpm', 'httpd');
my $host = `/bin/hostname`;
chomp $host;

foreach my $service(@services) {
   my $status = `/bin/ps cax | /bin/grep $service`;
   if (! $status) {
print "ALERT! $host: $service not running\n";
print "Trying to start service: $service\n";
system "/etc/init.d/$service start";
        }
   }

my $msg = MIME::Lite->new (
        Subject => 'Service monitor for $host',
        From => 'root@bampi.ro',
        To => $email,
        Type => 'text/html',
        Data => '',
);

#$msg->send();
