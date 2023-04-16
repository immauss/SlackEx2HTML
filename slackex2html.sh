#!/bin/bash
# Create array of usernames to IDs
# Create cache of User avatars
# Get number of entries in file with ".|length"
# start at 0 index and got to < $length
# use jq to extract each element of indexed item and assign to bash var
# output HTML using generated vars
# take a nap !
Debug() {
	if [ $DEBUG ]; then
		echo "debug: $@"
	}
DEBUG="1"
INPUT="$1"
RECORDS=$(jq '.|length $INPUT)
Debug "INPUT $INPUT RECORDS $RECORDS"