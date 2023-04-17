#!/bin/bash
# Create array of usernames to IDs
# Create cache of User avatars
# Get number of entries in file with ".|length"
# start at 0 index and got to < $length
# use jq to extract each element of indexed item and assign to bash var
# output HTML using generated vars

# This for the user to configure.
DEBUG="0"
SRCDIR="/Users/scott/Downloads/CatalystSlackExport" # Set this if you dont' want to use the current working directory.
DSTDIR="/Users/scott/SlackTest"
mkdir -p $DSTDIR


# Check to see if we are running on MacOS or Linux, then do some setup.
OS=$(uname)
if [ "$OS" == "Darwin" ]; then
	jq=$(which jq)
	if [ "x$jq" == "x" ]; then
		echo "Looks like you are on a Mac, but dont' have jq"
		echo "You need to use brew to install jq"
		exit
	fi
	Date() {
		date -r $( jq -r ".[$INDEX]|.ts" $INPUT | sed "s/\(^[0-9]*\)\..*$/\1/") +%T
		}
else
	jq=$(which jq)
	if [ "x$jq" == "x" ]; then
		echo "The jq utility was not found."
		echo "Use your distribution's package manager to install jq"
		exit
	fi
	Date() {
		date -d @$( jq -r ".[$INDEX]|.ts" $INPUT) +%T
		}
fi

# Setup a debug function..
Debug() {
	if [ $DEBUG -eq 1 ]; then
		echo -e "debug: $1"
		fi
	}

# This is where we start. It should be the root of the archive from Slack.
if [ -z $SRCDIR ]; then
	SRCDIR=$(pwd)
fi

# First we need to create the destination structure.
cd $SRCDIR
SRCDIRS=$(find . -type d | sed "s/^\.\///")

# then create the new structure in the destination
cd $DSTDIR
for DIR in $SRCDIRS; do 
	mkdir -p $DIR 2> /dev/null
done

# Process each file. The final dir structure will mirror the archive's structure, 
# but include sub folders for the year under each channel folder. 
# Files in each folder will be by month. 
#
for DIR in $SRCDIRS; do 
	Debug "DIR $DIR"
	cd ${SRCDIR}/${DIR}
	Debug "PWD $(pwd)"
	for MONTH in 01 02 03 04 05 06 07 08 09 10 11 12; do		
		
		# Setup the initial Table.
		for INPUT in $( ls ????-$MONTH-??.json 2> /dev/null| sort); do
			DATE=$( echo $INPUT | sed "s/.json$//")
			YEAR=$(echo $DATE | sed "s/\(^....\)-.*$/\1/")
			mkdir -p "${DSTDIR}/${DIR}/${YEAR}"
			OUTPUT="${DSTDIR}/${DIR}/${YEAR}/${MONTH}.html"
			if ! [ -f "$OUTPUT" ]; then
				echo "<html><body>" > $OUTPUT
			fi
			Debug "MONTH $MONTH\n YEAR $YEAR\n OUTPUT $OUTPUT\n PWD $(pwd)"
			echo "<h1>$DATE</h1><table>" >> $OUTPUT
			RECORDS=$(jq '.|length' $INPUT)   # File record count (number of messages in the file)
			LASTUSER="null"
			# process all the records in the file.
			INDEX=0
			Debug "OUTPUT $OUTPUT\n SRCDIR $SRCDIR\n INPUT $INPUT\n DATE $DATE\n YEAR $YEAR\n PWD $(pwd)"
			while [ $INDEX -lt $RECORDS ]; do 
				TS=$( Date )
				MSG=$( jq -r ".[$INDEX]|.text" $INPUT)
				if  echo $MSG | grep -isq http ; then
					Debug "$MSG\nTHERE'S a LINK IN THIS MSG!!!"
					#remove the < & > characters so the link will show up.
					# this should be fixed to make this an anchor tag.
					MSG=$( echo $MSG | tr '<|>' ' ')
				fi
				# This sets up the Username and avatar, but sets them to null if the last
				# entry was from the same user. This gives a cleaner look in the rendered html
				USER=$( jq -r ".[$INDEX]|.user_profile.real_name" $INPUT)
				if [ "$LASTUSER" != "$USER" ]; then		
					USERNAME=$USER
					AVATAR=$( jq -r ".[$INDEX]|.user_profile.image_72" $INPUT)
				else
					USERNAME=""
					AVATAR=""
				fi
				LASTUSER=$USER

				Debug "$TS\n$USER\n$MSG\n$AVATAR"
				# Create a new row in the table;
				echo "<tr><td><b>${USERNAME}</b></td><td><img src="$AVATAR"></td><td>$TS:</td><td> $MSG</td></tr>" >> $OUTPUT
				# increase the INDEX
				INDEX=$( expr $INDEX + 1)
	

			done 
			echo "</table>" >> $OUTPUT
		done  
		echo "</body></html>" >> $OUTPUT
	done

done