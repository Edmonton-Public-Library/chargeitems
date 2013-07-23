#!/s/sirsi/Unicorn/Bin/perl -w
####################################################
#
# Perl source file for project chargeitems 
# Purpose: This script charges items to a specific user
#          It is used in the case where items that are 
#          currently not checked out need to be checked
#          out en-masse to a user like EPLLCP-MISSING,
#          which is the only case to date that requires
#          this type of functionality.
# Method:  API-server commands.
# Requires: file structured as so:
# 1100056|2|4|31221106795649  |VIDEO GAME 793.932  ANA|
# Which can be derived from barcodes with 
# cat lcp_to_missing.lst | selitem -iB -oIB | selcallnum -iK -oKSA
#
# Charges items to a specific user.
#    Copyright (C) 2013  Andrew Nisbet
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# Author:  Andrew Nisbet, Edmonton Public Library
# Created: Tue Jul 23 11:58:59 MDT 2013
# Rev: 
#          0.0 - Dev. 
#
####################################################

use strict;
use warnings;
use vars qw/ %opt /;
use Getopt::Std;

# Environment setup required by cron to run script because its daemon runs
# without assuming any environment settings and we need to use sirsi's.
###############################################
# *** Edit these to suit your environment *** #
$ENV{'PATH'}  = qq{:/s/sirsi/Unicorn/Bincustom:/s/sirsi/Unicorn/Bin:/usr/bin:/usr/sbin};
$ENV{'UPATH'} = qq{/s/sirsi/Unicorn/Config/upath};
###############################################

# Trim function to remove whitespace from the start and end of the string.
# param:  string to trim.
# return: string without leading or trailing spaces.
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

my $VERSION    = qq{0.0};
my $USER_ID    = "";
my $TRX_NUM    = 1;
my $API_LN_COUNT = 0;
my $DATE = `date +%Y%m%d`;
$DATE = trim($DATE);
my $TIME = `date +%H%M%S`;
$TIME = trim($TIME);
my $STATION = "EPLMNA";
my $TRANSACTION_FILE = "TRX_charge_item.lst";
my $RESPONSE_FILE = "TRSP_charge_item.log";

#
# Message about this program and how to use it.
#
sub usage()
{
    print STDERR << "EOF";

	usage: $0 [-u LCP-MISSING]
Usage notes for chargeitems.pl. $0 takes a list of barcodes
on the command line and creates and runs API server commands
to charge them to a given user, or system card.

 -s STATION: Station library who performed this transaction (default EPLMNA).
 -u USERID : Mandatory, user id who will be charged.
 -U        : Update, run the API server commands, otherwise it just produces the commands.
 -x        : This (help) message.

example: $0 -x
example: cat LCP_Missing_items.lst | $0 -u LCP-MISSING -s"EPLMNA"
Version: $VERSION
EOF
    exit;
}

# Kicks off the setting of various switches.
# param:  
# return: 
sub init
{
    my $opt_string = 's:u:Ux';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if ( $opt{'x'} );
	if ( !$opt{'u'} )
	{
		usage();
	}
	else
	{
		$USER_ID = $opt{'u'} if ( $opt{'u'} );
	}
	$STATION = $opt{'s'} if ( $opt{'s'} );
}


#-----------------------------------------------------------
#create API server transaction to charge item:
#Discharge Item sample entry from history log below:
#E201005051120490628R ^S66CVFFADMIN^FEEPLMNA^FcNONE^FWADMIN^NQ31221040008513^UOABB-DISCARDCA2^IQKaren's test^IS1^Uf6405^dC3^rsY^OeY^Fv3000000^^O
#5/5/2010,11:20:49 Station: 0628 Request: Sequence #: 66 Command: Charge Item Part B
#station login user access:ADMIN  station library:EPLMNA  station login clearance:NONE  station user's user ID:ADMIN  item ID:31221040008513  user ID:ABB-DISCARDCA2  call number:Karen's test  copy number:1  user pin:6405  Client type: see client_types.h for values:3  rs:Y  holds block override:Y  Max length of transaction response:3000000
#-----------------------------------------------------------
#create transaction line for charge Item API server transaction
#-----------------------------------------------------------
#create transaction line
sub createTransactionLine
{
	my ($stationLibrary, $itemId, $userId, $callNumber, $copyNumber) = @_;
	my $transactionRequestLine = "";
	$TRX_NUM++;
	if ( $TRX_NUM > 99 ) 
	{
		$TRX_NUM = 1;
	}
	
	$transactionRequestLine = 'E';
	$transactionRequestLine .= $DATE;
	$transactionRequestLine .= $TIME;
	$transactionRequestLine .= '0001';
	$transactionRequestLine .= 'R'; #request
	$transactionRequestLine .= ' ';
	$transactionRequestLine .= '^S';
	$transactionRequestLine .= $TRX_NUM = '0' x ( 2 - length( $TRX_NUM ) ) . $TRX_NUM;
	$transactionRequestLine .= 'CV'; #Charge Item command code
	$transactionRequestLine .= 'FF'; #station login user access
	$transactionRequestLine .= 'ADMIN';
	$transactionRequestLine .= '^';
	$transactionRequestLine .= 'FE'; #station library
	$transactionRequestLine .= $stationLibrary;
	$transactionRequestLine .= '^';
	$transactionRequestLine .= 'FcNONE';
	$transactionRequestLine .= '^';
	$transactionRequestLine .= 'FW'; #station user's user ID
	$transactionRequestLine .= 'ADMIN';
	$transactionRequestLine .= '^';
	$transactionRequestLine .= 'NQ'; #Item ID
	$transactionRequestLine .= $itemId;
	$transactionRequestLine .= '^';
	$transactionRequestLine .= 'UO'; #
	$transactionRequestLine .= $userId;
	$transactionRequestLine .= '^';
	$transactionRequestLine .= 'IQ'; #Call Number
	$transactionRequestLine .= $callNumber;
	$transactionRequestLine .= '^';
	$transactionRequestLine .= 'IS'; #Copy Number
	$transactionRequestLine .= $copyNumber;
	$transactionRequestLine .= '^';
	$transactionRequestLine .= 'dC'; #Client type: see client_types.h for values
	$transactionRequestLine .= '3';  #3 = Both C WorkFlows and Java WorkFlows
	$transactionRequestLine .= '^';
	$transactionRequestLine .= 'rs'; #
	$transactionRequestLine .= 'Y';
	$transactionRequestLine .= '^';
	$transactionRequestLine .= 'Oe'; #holds block override
	$transactionRequestLine .= 'Y';
	$transactionRequestLine .= '^';
	$transactionRequestLine .= 'Fv'; #Max length of transaction response
	$transactionRequestLine .= '5000000';
	$transactionRequestLine .= '^';
	$transactionRequestLine .= '^';
	$transactionRequestLine .= 'O';
	
	#print LOGFILE "$selectionline\n";
	#print LOGFILE "$transactionRequestLine\n";
	$API_LN_COUNT++;
	return "$transactionRequestLine\n";
}

init();

# You can get the information for this script from just barcodes with 
# cat lcp_to_missing.lst | selitem -iB -oIB | selcallnum -iK -oKSA
# Which produces:
# 1100056|2|4|31221106795649  |VIDEO GAME 793.932  ANA|
open API, ">$TRANSACTION_FILE" or die "Error opening '$TRANSACTION_FILE': $!\n";
while ( <> )
{
	my ($catKey, $seqNum, $copyNum, $itemId, $callNum) = split( '\|', $_ );
	print "$catKey, $seqNum, $copyNum, $itemId, $callNum\n";
	print API createTransactionLine($STATION, $itemId, $USER_ID, $callNum, $copyNum);
}
close API;
print "Total of $API_LN_COUNT processed.\n";
# Run the API server commands.
if ( $opt{'U'} )
{
	`apiserver -h <$TRANSACTION_FILE >>$RESPONSE_FILE` if ( -s $TRANSACTION_FILE );
}

# EOF
