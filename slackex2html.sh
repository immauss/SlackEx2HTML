#!/bin/bash
# Create array of usernames to IDs
# Create cache of User avatars
# Get number of entries in file with ".|length"
# start at 0 index and got to < $length
# use jq to extract each element of indexed item and assign to bash var
# output HTML using generated vars
# take a nap !
Debug() {
	if [ $DEBUG -eq 1 ]; then
		echo "debug: $1"
		fi
	}
DEBUG="1"
INPUT="$1"
RECORDS=$(jq '.|length' $INPUT)
Debug "INPUT $INPUT RECORDS $RECORDS"
INDEX=0
while [ $INDEX -lt $RECORDS ]; do 
		TS=$( jq -r ".[$INDEX]|.ts" $INPUT)
		INDEX=$( expr $INDEX + 1)
		Debug $TS
done