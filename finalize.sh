#!/usr/bin/env bash

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

WD=$(pwd)
# This is the directory on the server where you are storing the files as seen from the web.
# Example: /SlackHistory 
RELDIR="file:///Users/scott/SlackTest/"
# Main site home page
HOME="https://vcisocatalyst.org"
# Name of Organization for Title pages
ORGNAME="vCISO Catalyst"
# Array for Month names
MONTHA=("NULL" "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec") 

# Create Channel index.
echo "<html><body>" > index.html
echo "<h1>$ORGNAME Slack History</h1>" >> index.html
for Channel in $( ls -d -1 */ | tr -d "/"); do
	echo "<a href=$Channel>#$Channel</a><br>" >> index.html
done
echo "</body></html>" >> index.html

# Process through channels 
for DIR in $(ls -d -1 */); do

	cd $WD/$DIR
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
				echo "$DIR $Year $Month ${Links[$Year-$Month]}"
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
