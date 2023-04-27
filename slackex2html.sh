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

# Things for the user to configure.
DEBUG="0"
# Where you unzipped the archive from Slack
SRCDIR="/Users/scott/Downloads/CatalystSlackExport/Test"
# where to put the output
DSTDIR="/Users/scott/SlackTest"
# RELDIR is the directory on the server where you are storing the files as seen from the web.
RELDIR="/resources/Site/SlackHistory"
# Main site home page
HOME="https://vcisocatalyst.org"
# Name of Organization for Title pages
ORGNAME="vCISO Catalyst"

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
USERCOUNT=0
while [ $INDEX -lt $URECORDS ]; do
        ID=$( jq -r ".[$INDEX].id" $SRCDIR/users.json )
        NAME=$( jq -r ".[$INDEX].real_name" $SRCDIR/users.json )
        Debug "$ID,$NAME"
        INDEX=$( expr $INDEX + 1 )
        Users[$ID]="$NAME"
		USERCOUNT=$( expr $USERCOUNT + 1 )
		if [ $(expr $USERCOUNT % 10) -eq 0 ]; then
			echo -n "."
		fi
done
echo
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

# Now we need to create some index files to make the generated HTML easier to navigate.
# Starts at Index of channels
# In each channel folder, there is an index wich lists:
#  YEAR:
#     Jan Feb Mar
#	  Apr May Jun
#     Jul Aug Sep
#     Oct Nov Dec
# Each month links to that months messages
# at top and bottom of each page, navigation to prev & next in
# chronological order.

# Array for Month names
# Element 0 is NULL because there is no Month 0, this make the element number align with the 
# numerical month.
MONTHA=("NULL" "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec") 

# Make sure we are in the destination directory
cd $DSTDIR
# Create Channel index.
echo "<html><body>" > index.html
echo "<h1>$ORGNAME Slack History</h1>" >> index.html
for Channel in $( ls -d -1 */ | tr -d "/"); do
	echo "<a href=\"$Channel/index.html\">#$Channel</a><br>" >> index.html
done
echo "</body></html>" >> index.html

# Process through channels 

for DIR in $(ls -d -1 */); do

	cd $DSTDIR/$DIR
	echo "Working in $(pwd)"
	Channel=$( echo $DIR | tr -d "/")
	# First create the Navigation from prev <-> Next. 
	files=($(find . -name "*.html"  | grep -v index.html |sort -n))
		for (( i=0; i<${#files[@]}; i++ )); do
			filename="${files[$i]}";
			if (( $i > 0 )); then
				prevfile="${files[$i-1]}"
				PREV="<a href=\"$RELDIR/$DIR/$prevfile\">Previous</a>"
			else
				PREV=""
			fi
			if (( $i < ${#files[@]}-1 )); then
				nextfile="${files[$i+1]}"
				NEXT="<a href=\"$RELDIR/$DIR/$nextfile\">Next</a>"
			else
				NEXT=""
			fi
			# Insert Navigation
			NAVIGATION="<a href=\"$HOME\">Home</a></br><a href=\"$RELDIR/index.html\">Channel Index</a> </p>/$PREV --- $NEXT</br>"

			sed -i "" "s|xxxNAVIGATIONxxx|$NAVIGATION|g" $filename
		done
		# Now create the channel index file based on available month files.
		# filenames look like: "./2023/04.html"
		echo "<html><body>" > index.html
		echo "<center><h2>Index of <i>#$Channel</i> at $ORGNAME</h2></center>" >> index.html
		echo "<a href=\"$HOME\">Home</a></br><a href=\"$RELDIR/index.html\">Channel Index</a>" >> index.html
		declare -A Links
		for (( i=0; i<${#files[@]}; i++ )); do
			filename="${files[$i]}";
			YEAR=$( echo $filename | sed "s/^\.\/\(....\)\/..\.html$/\1/")
			YEARS=(${YEARS[@]} "$YEAR")
			MONTH=${MONTHA[$(echo $filename | sed "s/^\.\/....\/\(..\)\.html$/\1/;s/^0//")]}
			Links[$YEAR-$MONTH]="<a href=\"$filename\">$MONTH</a>"
		done
		# Make YEARS array unique so we can use it for table creation.
		YEARS=($(for x in "${YEARS[@]}"; do echo "${x}"; done | sort -ru))
		for Year in ${YEARS[@]}; do 
			
			for Month in ${MONTHA[@]}; do
				#echo "$DIR $Year $Month ${Links[$Year-$Month]}"
				if [ "x${Links[$Year-$Month]}" == "x" ]; then
					Links[$Year-$Month]="$Month"
				fi
			done
			echo "<h3>$Year</h3>" >> index.html
			echo "<table border="1">" >> index.html
			echo "<tr><td>${Links[${Year}-Jan]}</td><td>${Links[${Year}-Feb]}</td><td>${Links[${Year}-Mar]}</td></tr>" >> index.html
			echo "<tr><td>${Links[${Year}-Apr]}</td><td>${Links[${Year}-May]}</td><td>${Links[${Year}-Jun]}</td></tr>" >> index.html
			echo "<tr><td>${Links[${Year}-Jul]}</td><td>${Links[${Year}-Aug]}</td><td>${Links[${Year}-Sep]}</td></tr>" >> index.html
			echo "<tr><td>${Links[${Year}-Oct]}</td><td>${Links[${Year}-Nov]}</td><td>${Links[${Year}-Dec]}</td></tr>" >> index.html
			echo "</table>" >> index.html			
		done 
		echo "</body></html>"  >> index.html
		# Make sure these are clean for next run
		YEARS=()
		Links=()
done
