#!/bin/bash

# Author: Ali Rabiei
# Purpose: This script monitors the logins to system
# Creation Date: 08/31/2020
# Last Modificat`ion Date: 08/31/2020


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
    '-t')
        shift
        if [ -z "$TIME" ]; then
            TIME="${1}"    
        fi
        shift
    ;;
    *)
        echo "unrecognized flag."
        shift
    ;;
    esac

done

: "${TYPE:=all}"