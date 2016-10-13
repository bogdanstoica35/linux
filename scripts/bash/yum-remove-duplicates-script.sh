#!/bin/bash

# install yum-utils first
yum -y install yum-utils

# list all yum packages duplicates
package-cleanup --dupes

# create a file dupes.txt with the duplicate packages
package-cleanup --dupes > dups.txt

# remove lower version of the duplicate packages from the rpm local database
for i in `cat dups.txt | awk 'NR % 2 == 1'`; do rpm -e --nodeps $i; done
