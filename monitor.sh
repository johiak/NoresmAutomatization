#!/bin/bash

## This program monitors /projects/NS2345K/cases for new simulations

## Some initializing
CURRENT_DIR=/projects/NS2345K/noresm_automatization
CASES_DIR=$CURRENT_DIR/cases
TARGET_DIR=/projects/NS2345K/noresm/cases

cd $CASES_DIR
if [ -e cases_current ]; then
    /usr/bin/rm cases_current
fi

if [ -e cases_new ]; then
    /usr/bin/rm cases_new
fi

DATE_PREV=`head -n 1 cases_old`

/usr/bin/tail -n +2 cases_old > cases_tmp
/usr/bin/mv cases_tmp cases_old

# Loop over all sub-directories and save those which are new
cd $TARGET_DIR
for dir in *
do
    if [ -d $dir ]; then
	echo "$dir" >> $CASES_DIR/cases_current
	if ! /usr/bin/grep -Fxq "$dir" $CASES_DIR/cases_old
	then
	    echo "$dir" >> $CASES_DIR/cases_new
	fi
    fi
done

# Check the datestamp so that we can omit those that were modified less than 30 min ago
cd $CASES_DIR
if [ -e cases_new ]; then
    while read sim
    do
	moddate=`stat -c %Y $TARGET_DIR/$sim`
	cdate=`date +%s`
	diff_sec=`expr $cdate - $moddate`
	if [ $diff_sec -lt 1800 ]; then
	    sed -i "/$sim/d" cases_new
	    sed -i "/$sim/d" cases_current
	fi
    done<cases_new
fi

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

## Send an email to johiak
/usr/bin/mail -s "New simulations in ${TARGET_DIR}" johan.liakka@nersc.no < new_cases_${DATE_YYMMDD}

## Run check number of years of new sims and run ESMValTool
# if [ -e cases_new ]; then
#    $CURRENT_DIR/check_yrs.sh
# fi
