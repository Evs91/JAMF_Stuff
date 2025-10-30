#!/bin/bash
#######################################################
# A script to collect the Version of Fortinet EDR. 
# Covers both pre v6 and v6+ versions as of 10/10/2024
#######################################################

FILE=/Applications/FortiEDR.app/fortiedr_collector.sh
if [ -f "$FILE" ]; then
    upload=$(/bin/bash /Applications/FortiEDR.app/fortiedr_collector.sh version | cut -d ',' -f1 | cut -d ' ' -f3)
    RESULT=$upload
    /bin/echo "<result>$RESULT</result>"
else 
    upload=$(/bin/bash /Applications/FortiEDR.app/Contents/Library/LaunchServices/fortiedr_collector.sh version | cut -d ',' -f1 | cut -d ' ' -f3)
    RESULT=$upload
    /bin/echo "<result>$RESULT</result>"
fi
