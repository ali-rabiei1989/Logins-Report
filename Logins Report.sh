#!/bin/bash

# Author: Ali Rabiei
# Purpose: This script monitors the logins to system
# Creation Date: 08/31/2020
# Last Modificat`ion Date: 08/31/2020

# parsing options
while [[ $# -gt 0 ]] 
do

    OPTION=${1}

    case $OPTION in
    '-a'|'--all')
        if [ -z "$TYPE" ]; then
            TYPE='all' 
        else
            echo "Multiple login log type is issued."
            exit 1
        fi
        shift
    ;;
    '-f'|'--failed')
        if [ -z "$TYPE" ]; then
            TYPE='failed'    
        else
            echo "Multiple login log type is issued."
            exit 1
        fi

        shift
    ;;
    '-s'|'--successful')
        if [ -z "$TYPE" ]; then
            TYPE='successful'    
        else
            echo "Multiple login log type is issued."
            exit 1
        fi
        shift
    ;;
    '-p'|'--period')
        shift
        if [ -z "$PERIOD" ]; then
            PERIOD="${1}"    
        fi
        shift
    ;;
    '-r'|'--recipient')
        shift
        if [ -z "$RECIPIENT" ]; then
            RECIPIENT="${1}"    
        fi
        shift
    ;;
    '-u'|'--user')
        shift
        if [ -z "$TGTUSER" ]; then
            TGTUSER="${1}"    
        fi
        shift
    ;;
    '-c'|'--cron')
        shift
        CRON=1
        FREQ=${1}
        IFS='@'
        read -ra F <<< $FREQ 
        DATEFREQ="${F[0]}"
        TIMEFREQ="${F[1]}"

        if [[ $DATEFREQ =~ every[[:digit:]]+(day|month|hour|min)s?$ ]]
        then
            FREQNO=$(grep -Eo '*[[:digit:]]*' <<< "$DATEFREQ")
            FREQUNIT=$(grep -Eo '*(day|month|hour|min)*' <<< "$DATEFREQ")

            if [[ $FREQUNIT == 'day' && ( $FREQNO == 0 || $FREQNO -gt 31 ) ]]
            then
                echo "Invalid day number: day must be between 1 and 31"
                exit 1
            fi

        else 
            echo "Invalid frequency format: $DATEFREQ"
            exit 1
        fi

        if [[ $TIMEFREQ =~ ^[[:digit:]][[:digit:]]?:[[:digit:]][[:digit:]]?$ ]]
        then
            
            HOUR=$(grep -Eo '^[[:digit:]][[:digit:]]?*' <<< "$TIMEFREQ")
            MIN=$(grep -Eo '*[[:digit:]][[:digit:]]?$' <<< "$TIMEFREQ")
            if [[ $HOUR -ge 24 ]]
            then
                echo "Invalid time format : $TIMEFREQ"
                exit 1
            fi

            if [[ $MIN -ge 60 ]]
            then 
                echo "Invalid time format : $TIMEFREQ"
                exit 1
            fi

        else
            echo "Invalid time format: $TIMEFREQ"
        fi
        
        shift
    ;;
    *)
        echo "Unrecognized Option : ${1}"
        exit 1
    ;;
    esac

done

# Set default values
: "${TYPE:=all}"
: "${PERIOD:=-7days}"
: "${RECIPIENT:=root}"

# Output file location
OUTFILE="/tmp/logins-report_$(date +'%m-%d-%Y_%H-%M').report"

echo "------------------------ List of $TYPE logins $(if [ -n "$TGTUSER" ]; then echo "for $TGTUSER"; fi) on $(hostname) ------------------------" > "$OUTFILE"

# Decide which command must be executed
if [[ "$TYPE" == "failed" ]]; then
    last -ai --since "$PERIOD" -f "/var/log/btmp" $(if [ -n "$TGTUSER" ]; then echo "$TGTUSER"; fi) >> "$OUTFILE" 
elif [[ "$TYPE" == 'successful' ]]; then
    last -ai --since "$PERIOD" -f "/var/log/wtmp" $(if [ -n "$TGTUSER" ]; then echo "$TGTUSER"; fi)>> "$OUTFILE" 
else
    last -ai --since "$PERIOD" -f "/var/log/wtmp" -f "/var/log/btmp" $(if [ -n "$TGTUSER" ]; then echo "$TGTUSER"; fi) >> "$OUTFILE" 
fi

# Send report via Email
mail -s "logins report on $(hostname)" "$RECIPIENT" < "$OUTFILE"

if [[ $CRON == 1 ]]
then

    ENTRY=$"$MIN $HOUR */$FREQNO * * root /usr/bin/loginreport --$TYPE --recipient $RECIPIENT --period -$FREQNO"" $(if [ -n "$TGTUSER" ]; then echo --user "$TGTUSER"; fi) > /dev/null 2>&1"
    echo "$ENTRY" >> /etc/crontab
fi