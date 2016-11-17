#!/bin/bash

# Create progress dots function
show_dots() {
	while ps $1 >/dev/null ; do
	printf "."
	sleep 1
	done
	printf "\n"
}

# execution

unizp -qq whatever * show_dots $!
