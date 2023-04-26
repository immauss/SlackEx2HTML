#!/usr/bin/env bash
# Create array of usernames to IDs
# Create cache of User avatars
# Get number of entries in file with ".|length"
# start at 0 index and got to < $length
# use jq to extract each element of indexed item and assign to bash var
# output HTML using generated vars


# Check message for UID pattern <U..........>. Use sed.. Then set variable for user with AWK against 
# cleaned up list of users to store actual user's real name in variable. Then use sed again 
# to replace it in the message. 
# To then repeat this until there are no longer any user IDs in the message. Maybe this 
# Should be a function?  
# Use " while ! grep UID.Patter msg; do" for iteration ...

# This for the user to configure.
DEBUG="0"
SRCDIR="/Users/scott/Downloads/CatalystSlackExport" # Set this if you dont' want to use the current working directory.
DSTDIR="/Users/scott/SlackTest"
mkdir -p $DSTDIR
# This is where we start. It should be the root of the archive from Slack.
if [ -z $SRCDIR ]; then
	SRCDIR=$(pwd)
fi

# Pre run Cleanup
if [ -f slackex2html.debug ]; then 
	rm $SRCDIR/slackex2html.debug
fi


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
		echo -e "debug:\n$1" | tee -a  $SRCDIR/slackex2html.debug
		fi
	}
# First we need to create the destination structure.
cd $SRCDIR
SRCDIRS=$(find . -mindepth 1 -type d | sed "s/^\.\///" | sort )

# then create the new structure in the destination
cd $DSTDIR
for DIR in $SRCDIRS; do 
	mkdir -p $DIR 2> /dev/null
done
# Create an associative array for the user name to ID mapping.
Debug " $SRCDIR/users.json"
URECORDS=$( jq ".|length" $SRCDIR/users.json)
INDEX=0
declare -A Users
echo "Reading Users into array for replacements later"
while [ $INDEX -lt $URECORDS ]; do
        ID=$( jq -r ".[$INDEX].id" $SRCDIR/users.json )
        NAME=$( jq -r ".[$INDEX].real_name" $SRCDIR/users.json )
        Debug "$ID,$NAME"
        INDEX=$( expr $INDEX + 1 )
        Users[$ID]="$NAME"
done
# Process each file. The final dir structure will mirror the archive's structure, 
# but include sub folders for the year under each channel folder. 
# Files in each folder will be by month. 
#
echo "Now processing Channels"
for DIR in $SRCDIRS; do 
	echo -e "\nChannel #$DIR"
	cd ${SRCDIR}/${DIR}
	Debug "PWD $(pwd)"
	for MONTH in 01 02 03 04 05 06 07 08 09 10 11 12; do	
		Debug "MONTH $MONTH"		
		for INPUT in $( ls ????-$MONTH-??.json 2> /dev/null| sort); do
			Debug "INPUT at Start -$INPUT-"
			DATE=$( echo $INPUT | sed "s/.json$//")
			YEAR=$(echo $DATE | sed "s/\(^....\)-.*$/\1/")
			mkdir -p "${DSTDIR}/${DIR}/${YEAR}"
			OUTPUT="${DSTDIR}/${DIR}/${YEAR}/${MONTH}.html"
			if ! [ -f "$OUTPUT" ]; then
				echo "<html><body>" > $OUTPUT
				echo "<center><h1>#$DIR</h1></center>" >> $OUTPUT
				echo "xxxNAVIGATIONxxx" >> $OUTPUT
			fi
			Debug "MONTH $MONTH\n YEAR $YEAR\n OUTPUT $OUTPUT\n PWD $(pwd)"
			# Setup the initial Table.
			echo "<h1>$DATE</h1><table>" >> $OUTPUT
			RECORDS=$(jq '.|length' $INPUT)   # File record count (number of messages in the file)
			LASTUSER="null"
			# process all the records in the file.
			INDEX=0
			Debug "OUTPUT $OUTPUT\n SRCDIR $SRCDIR\n INPUT $INPUT\n DATE $DATE\n YEAR $YEAR\n PWD $(pwd)"
			while [ $INDEX -lt $RECORDS ]; do 
				if [ $(expr $INDEX % 100) -eq 0 ]; then 
					echo -n "."
				fi
				TS=$( Date )
				MSG=$( jq -r ".[$INDEX]|.text" $INPUT | tr '<|>|\r' ' ')
# 				if  echo $MSG | grep -isq http ; then
# 					Debug "$MSG\nTHERE'S a LINK IN THIS MSG!!!"
# 					#remove the < & > characters so the link will show up.
# 					# this should be fixed to make this an anchor tag.
# 					MSG=$( echo $MSG | tr '<|>' ' ')
# 				fi
				# Replace the UIDs with actual user names on mentions

				while echo "$MSG" | tr -d "\n" | egrep -sq "[@\b]U[A-Z0-9]{10}\b" ; do 
					
					ID=$(echo "$MSG" | tr -d "\n" | sed -E "s/^.*(U[A-Z0-9]{10}).*$/\1/")
					if [ "${Users[$ID]}x" != "x" ]; then
						Debug "ID: $ID User: \"${Users[$ID]}\"\nMSG: $MSG"
						MSG=$(echo "$MSG" | sed "s/${ID}/${Users[$ID]}/g")
						if [ $? -ne 0 ]; then
							Debug "MSG: $MSG\nID: $ID\nUser: \"${Users[$ID]}\""
						fi
					else 
						if [ ${#ID} -eq 11 ]; then
							MSG=$(echo "$MSG" | sed "s/${ID}/UNKNOWN/g")
							Debug "##NO User Match ##\nMSG: \"$MSG\"\nID: $ID\nUser: ${Users[$ID]}"
						fi
						if [ $? -ne 0 ]; then
							Debug "##NO User Match ##\nsed command failed.\nMSG: \"$MSG\"\nID: $ID\nUser: ${Users[$ID]}"
						fi
					fi	
					Debug "Found $ID in MSG:\n$MSG\nFrom: $INPUT at INDEX: $INDEX"
				done 
				# This sets up the Username and avatar, but sets them to null if the last
				# entry was from the same user. This gives a cleaner look in the rendered html
				USER=$( jq -r ".[$INDEX]|.user_profile.real_name" $INPUT)
				Debug "LAST $LASTUSER Current $USER USERNAME $USERNAME"
				if [ "$LASTUSER" != "$USER" ]; then		
					USERNAME="$USER"
					AVATAR="<img src=\"$( jq -r ".[$INDEX]|.user_profile.image_72" $INPUT)\">"
				else
					USERNAME=""
					AVATAR=""
				fi
				LASTUSER=$USER
				Debug "$TS\n$USER\n$MSG\n$AVATAR"
				if [ "$USERNAME" == "null" ]; then
					USERNAME=""
					AVATAR=""
				fi
				# Create a new row in the table;
				echo "<tr><td style=\"vertical-align: top\"><b>${USERNAME}</b></td><td style=\"vertical-align: top\">$AVATAR</td><td style=\"vertical-align: top\">$TS:</td><td style=\"vertical-align: top\"> $MSG</td></tr>" >> $OUTPUT
				# increase the INDEX
				INDEX=$( expr $INDEX + 1)
			done 
			Debug "Close table INPUT $INPUT OUTPUT $OUTPUT"
			if [ -f $OUTPUT ]; then
				echo "</table>" >> $OUTPUT
			fi	
		done 
		Debug "Close tag INPUT $INPUT \n OUTPUT $OUTPUT" 
		# We first check to see if the file exists as it may not.
		# This happens when there is no source file for the months in this loop.
		if [ -f "$OUTPUT" ]; then
			if [ $( grep -c xxxNAVIGATIONxxx $OUTPUT) -lt 2 ]; then 
				echo "xxxNAVIGATIONxxx" >> $OUTPUT
				echo "</body></html>" >> $OUTPUT
			fi
		fi
	done

done
# just to make the screen output prettier.
echo