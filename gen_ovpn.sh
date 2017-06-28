#!/bin/bash

if [ -z $1 ] || [ -z $2 ]; then
	echo "Usage: $0 <username> <password> [valid-days]" 
	exit -1
fi

USERNAME=$1
PASSWORD=$2
VALID=${3:-14}
PEMFILE="cert-${USERNAME}.pem"
OVPNFILE="softfire-${USERNAME}.ovpn"

API_USER="portaluser"
API_PW="__changeme__"
API_URL="http://172.20.30.8:5080"

if [ -f $OVPNFILE ]; then
	echo "$OVPNFILE already exsists!"
	exit 0
else
	set -x
	COOKIE_FILE=$(tempfile)
	echo "Logging in..."
	curl -X POST --cookie-jar $COOKIE_FILE --form "username=$API_USER" --form "password=$API_PW" ${API_URL}/login
	echo ""
	echo "requesting certificate..."
	curl -s -X POST --cookie $COOKIE_FILE --form "username=${USERNAME}" --form "password=${PASSWORD}" --form "days=$VALID" ${API_URL}/certificates | tee $OVPNFILE
	echo "Logout.."
	curl -X GET --cookie-jar $COOKIE_FILE --cookie $COOKIE_FILE ${API_URL}/logout
	echo ""
	rm $COOKIE_FILE
fi
