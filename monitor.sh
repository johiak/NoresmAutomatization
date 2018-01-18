#!/bin/bash

## This program monitors /projects/NS2345K/cases for new simulations

CURRENT_DIR=/nird/home/johiak/monitor_cases
TARGET_DIR=/projects/NS2345K/noresm/cases

cd $CURRENT_DIR
if [ -e cases_current ]; then
    /usr/bin/rm cases_current
fi

if [ -e cases_new ]; then
    /usr/bin/rm cases_new
fi

DATE_PREV=`head -n 1 cases_old`

/usr/bin/tail -n +2 cases_old > cases_tmp
/usr/bin/mv cases_tmp cases_old

cd $TARGET_DIR
for dir in *
do
    if [ -d $dir ]; then
	echo "$dir" >> $CURRENT_DIR/cases_current
	if ! /usr/bin/grep -Fxq "$dir" $CURRENT_DIR/cases_old
	then
	    echo "$dir" >> $CURRENT_DIR/cases_new
	fi
    fi
done

cd $CURRENT_DIR
/usr/bin/mv cases_current cases_old

DATE_TODAY=`date`
DATE_YYMMDD=`date +%Y%m%d`

/usr/bin/sed -i "1i ${DATE_TODAY}" cases_old
echo "New cases between" > new_cases_${DATE_YYMMDD}
echo "${DATE_PREV} and" >> new_cases_${DATE_YYMMDD}
echo "${DATE_TODAY}" >> new_cases_${DATE_YYMMDD}
echo "---------------------------------------------------" >> new_cases_${DATE_YYMMDD}
if [ -e cases_new ]; then
    while read dir
    do
	SIM_INFO=`ls -l --time-style="+%Y-%m-%d" ${TARGET_DIR} | grep -w ${dir}`
	echo $SIM_INFO >> new_cases_${DATE_YYMMDD}
    done <cases_new
else
    echo "NO NEW CASES TO REPORT" >> new_cases_${DATE_YYMMDD}
fi

# Send an email
/usr/bin/mail -s "New simulations in ${TARGET_DIR}" johan.liakka@nersc.no < new_cases_${DATE_YYMMDD}
