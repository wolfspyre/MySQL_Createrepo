MySQL_Createrepo
================
This is a simple script to download a list of the RPMs released for the various major versions of MySQL
It will then parse it, and subsequently download the needed RPMs
Afterwards, it will place them into a directory structure conducive to a yum repository tree, and can do the createrepo part.


This script is copyright 2012 Datapipe.
It's not perfect yet, suggestions/fixes are welcome.

1.0.1:
updated the archive repo fetch loop to exclude RPMs which match /m[0-9]-[0-9]/ to prevent pre-GA rpms from making it into the repos
