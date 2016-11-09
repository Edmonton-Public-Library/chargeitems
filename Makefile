####################################################
# Makefile for project chargeitems 
# Created: Tue Jul 23 11:58:59 MDT 2013
#
# Manages distribution of application to production server.
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
# Written by Andrew Nisbet at Edmonton Public Library
# Rev: 
#      0.1 - Removed get rule. 
#      0.0 - Dev. 
####################################################
# Change comment below for appropriate server.
SERVER=eplapp.library.ualberta.ca
SERVER_TEST=edpl-t.library.ualberta.ca
USER=sirsi
REMOTE=~/Unicorn/Bincustom/
LOCAL=~/projects/chargeitems/

put: test
	scp ${LOCAL}chargeitems.pl ${USER}@${SERVER_TEST}:${REMOTE}
	scp ${LOCAL}chargeitems.pl ${USER}@${SERVER}:${REMOTE}
 
test:
	perl -c chargeitems.pl

