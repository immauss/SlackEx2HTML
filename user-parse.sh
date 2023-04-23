#!/bin/zsh
URECORDS=$( jq ".|length" users.json)
INDEX=0
declare -A Users
while [ $INDEX -lt $URECORDS ]; do 
	ID=$( jq -r ".[$INDEX].id" users.json )
	NAME=$( jq -r ".[$INDEX].real_name" users.json )
	echo "$ID,$NAME"
	INDEX=$( expr $INDEX + 1 )
	Users[$ID]="$NAME"
done
echo "${Users[U04T58A64PJ]}"

for i in "${!Users[@]}"; do 
	echo "${i}=${Users[$i]}"
done
