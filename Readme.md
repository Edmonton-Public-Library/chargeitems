=== Tue Jul 23 11:58:59 MDT 2013 ===

Project Notes
-------------
This script does one thing; it charges items to a user. You must make sure that all the items you select must not already be charged to a user already.


Instructions for Running
------------------------
/s/sirsi/Unicorn/Bincustom/chargeitems [switches]
Example:
```
cat bar_codes.lst \| selitem -iB -oIB \| selcallnum -iK -oKSA \| chargeitems.pl -u"ILS-DISCARD"
cat bar_codes.lst \| chargeitems.pl -b -u"ILS-DISCARD"
```

Product Description
--------------------
Perl script written by Andrew Nisbet for Edmonton Public Library, distributable by the enclosed license.

Repository Information
----------------------
This product is under version control using Git.

Dependencies
------------
Requires: file structured as so:
```
'1100056|2|4|31221106795649  |VIDEO GAME 793.932  ANA|'
```
Which can be derived from barcodes with
```
cat lcp_to_missing.lst | selitem -iB -oIB | selcallnum -iK -oKSA
```

Known Issues
---
None
