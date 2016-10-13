#!/bin/bash

# install yum-utils package
yum -y install yum-utils

# list all duplicate packages
package-cleanup --dupes

# create a file duplicates.txt with a list of the duplicate packages
package-cleanup --dupes > dups.txt

# remove lower version of the duplicate package from the rpm local database
for i in `cat dups.txt | awk 'NR % 2 == 1'`; do rpm -e --nodeps $i; done
