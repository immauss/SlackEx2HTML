#!/bin/bash
# Create array of usernames to IDs
# Create cache of User avatars
# Get number of entries in file with ".|length"
# start at 0 index and got to < $length
# use jq to extract each element of indexed item and assign to bash var
# output HTML using generated vars

# Issues: 
#	Links are stuck in "<>" which breaks them in the html
OS=$(uname)
if [ "$OS" == "Darwin" ]; then
	Date() {
		date -r $( jq -r ".[$INDEX]|.ts" $INPUT | sed "s/\(^[0-9]*\)\..*$/\1/") +%T
		}
else
	Date() {
		date -d @$( jq -r ".[$INDEX]|.ts" $INPUT) +%T
		}
fi

Debug() {
	if [ $DEBUG -eq 1 ]; then
		echo -e "debug: $1"
		fi
	}
DEBUG="0"
INPUT="$1"
RECORDS=$(jq '.|length' $INPUT)
Debug "INPUT $INPUT RECORDS $RECORDS"
INDEX=0
TITLE=$( echo $INPUT | sed "s/.json$//")
echo "<html><body><h1>$TITLE</h1><table>"
while [ $INDEX -lt $RECORDS ]; do 
	TS=$( Date )
	USER=$( jq -r ".[$INDEX]|.user_profile.real_name" $INPUT)
	MSG=$( jq -r ".[$INDEX]|.text" $INPUT)
	AVATAR=$( jq -r ".[$INDEX]|.user_profile.image_72" $INPUT)
	Debug "$TS\n$USER\n$MSG\n$AVATAR"
	echo "<tr><td><b>$TS</b></td><td><img src="$AVATAR"></td><td>${USER}:</td><td> $MSG</td></tr>"

	INDEX=$( expr $INDEX + 1)
done
echo "</table></body></html>"
