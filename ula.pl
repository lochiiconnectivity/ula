#!/usr/bin/perl

#ula.pl - generate Locally Assigned prefix for ULA as per http://tools.ietf.org/html/rfc4193#section-3.2.2
#tdcdf1 - 05/06/10 - version 1.0

use strict;
use Data::Dumper;
use Digest::SHA1 qw(sha1_hex);
use Time::HiRes qw(time);

#Check arguments
unless ($ARGV[0]) {
	print "Usage: $0 <interface>\n";
	print "Generate ULA for interface <interface>\n";
	exit;
}	

#Following the RFC literally

#1) Obtain the current time of day in 64-bit NTP format [NTP].
my $curtime = &makeSixtyFourBitTimeStamp();

#2) Get EUI-64 from the interface specified
my $eui64 = &getEUI64ForInt($ARGV[0]);

#3) Concatenate the time of day with the system-specific identifier in order to create a key.
my $key = $curtime . $eui64;

#4) Compute an SHA-1 digest on the key 
my $sha1 = sha1_hex($key);

#5) Use the least significant 40 bits as the Global ID.
my $ls40 = substr($sha1, 30, 10);
$ls40=~s/(\S{2})(\S{2})(\S{2})(\S{2})(\S{2})/$1$2:$3$4:$5/g;

#6) Concatenate FC00::/7, the L bit set to 1, and the 40-bit Global ID to create a Local IPv6 address prefix.
my $prefix = "fd00:". $ls40 . "::/7";

##Now display our handiwork
print "$prefix\n";

####SUBS BELOW HERE
sub makeSixtyFourBitTimeStamp {
	my $ntp_epoch_diff = 2208988800;
	my $time = time();
	my $ts = pack ('LL', (int($time) + $ntp_epoch_diff), (($time - int($time)) * (2**32)));
	return $ts;
}
sub getEUI64ForInt {
	my $int = shift;
	my $eui64;
	my $ifconfig = `ifconfig $int`;
	if ($ifconfig =~m/inet/) {
	        if ($ifconfig =~m/ether (.*)/) {
			my $mac = $1;
			my @mac_octets = map hex, split (":", $mac);
			my @eui64_octets = ($mac_octets[0] ^ 0x02, @mac_octets[1..2], 0xff, 0xfe, @mac_octets[3..5]);
			my $eui64 = pack ("CCCCCCCC", @eui64_octets);
			return $eui64;
	        }
	        else {
	                print "No mac address?\n";
	                exit;
	        }
	}
	else {
	        print "Invalid interface $int\n";
	        exit;
	}
	return $eui64;
}
