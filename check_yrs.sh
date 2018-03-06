#!/bin/bash

CASES_DIR=/projects/NS2345K/noresm_automatization/cases
ESMVAL_DIR=/projects/NS2345K/noresm_automatization/ESMValTool
TARGET_DIR=/projects/NS2345K/noresm/cases
NAMELIST=/nird/home/johiak/NorESMValTool/mods/namelists/namelist_portrait_diagram_RMSE_global.xml

cd $CASES_DIR

file_spec=(cam.h0. clm2.h0. cice.h. micom.hy.)

## Determine year ranges for new simulations
while read sim
do
    FIRST_YR_TS=()
    LAST_YR_TS=()
    FIRST_YR_CLIMO=()
    LAST_YR_CLIMO=()
    COUPLED=()
    m=0
    for comp in atm lnd ice ocn
    do
	if [ $comp == ocn ]; then
	    file_head="${sim}.${file_spec[$m]}????"
	    file_prefix=$TARGET_DIR/$sim/$comp/hist/$file_head
	    first_file=`ls ${file_prefix}* 2>/dev/null | head -n 1`
	    last_file=`ls ${file_prefix}* 2>/dev/null | tail -n 1`
	    if [ -z $first_file ]; then
		file_head="${sim}.micom.hm.????-??"
		file_prefix=$TARGET_DIR/$sim/$comp/hist/$file_head
		first_file=`ls ${file_prefix}* 2>/dev/null | head -n 1`
		last_file=`ls ${file_prefix}* 2>/dev/null | tail -n 1`
		if [ -z $first_file ]; then
		    file_head="${sim}.pop.h.????-??"
		    file_prefix=$TARGET_DIR/$sim/$comp/hist/$file_head
		    first_file=`ls ${file_prefix}* 2>/dev/null | head -n 1`
		    last_file=`ls ${file_prefix}* 2>/dev/null | tail -n 1`
		    if [ -z $first_file ]; then
			fyr_in_dir=-1
			lyr_in_dir=-1
		    else
			fyr_in_dir_prnt=`echo $first_file | rev | cut -c 7-10 | rev`
			fyr_in_dir=`echo $fyr_in_dir_prnt | sed 's/^0*//'`
			lyr_in_dir_prnt=`echo $last_file | rev | cut -c 7-10 | rev`
			lyr_in_dir=`echo $lyr_in_dir_prnt | sed 's/^0*//'`
			if [ "$last_file" != "$TARGET_DIR/$sim/$comp/hist/${sim}.pop.h.${lyr_in_dir_prnt}-12.nc" ]; then
			    let "lyr_in_dir = $lyr_in_dir - 1"
			fi
		    fi
		else
		    fyr_in_dir_prnt=`echo $first_file | rev | cut -c 7-10 | rev`
		    fyr_in_dir=`echo $fyr_in_dir_prnt | sed 's/^0*//'`
		    lyr_in_dir_prnt=`echo $last_file | rev | cut -c 7-10 | rev`
		    lyr_in_dir=`echo $lyr_in_dir_prnt | sed 's/^0*//'`
		    if [ "$last_file" != "$TARGET_DIR/$sim/$comp/hist/${sim}.micom.hm.${lyr_in_dir_prnt}-12.nc" ]; then
			let "lyr_in_dir = $lyr_in_dir - 1"
		    fi
		fi
	    else
		fyr_in_dir_prnt=`echo $first_file | rev | cut -c 4-7 | rev`
		fyr_in_dir=`echo $fyr_in_dir_prnt | sed 's/^0*//'`
		lyr_in_dir_prnt=`echo $last_file | rev | cut -c 4-7 | rev`
		lyr_in_dir=`echo $lyr_in_dir_prnt | sed 's/^0*//'`
	    fi
	else
	    file_head="${sim}.${file_spec[$m]}????-??"
	    file_prefix=$TARGET_DIR/$sim/$comp/hist/$file_head
	    first_file=`ls ${file_prefix}* 2>/dev/null | head -n 1`
            last_file=`ls ${file_prefix}* 2>/dev/null | tail -n 1`
            if [ -z $first_file ]; then
		fyr_in_dir=-1
		lyr_in_dir=-1
	    else
		fyr_in_dir_prnt=`echo $first_file | rev | cut -c 7-10 | rev`
		fyr_in_dir=`echo $fyr_in_dir_prnt | sed 's/^0*//'`
		lyr_in_dir_prnt=`echo $last_file | rev | cut -c 7-10 | rev`
		lyr_in_dir=`echo $lyr_in_dir_prnt | sed 's/^0*//'`
	    fi
	    if [ "$last_file" != "$TARGET_DIR/$sim/$comp/hist/${sim}.${file_spec[$m]}${lyr_in_dir_prnt}-12.nc" ]; then
		let "lyr_in_dir = $lyr_in_dir - 1"
	    fi
	fi
	FIRST_YR_TS+=($fyr_in_dir)
	LAST_YR_TS+=($lyr_in_dir)
	let m++
    done
    COUPLED_FLAG=1
    for ((m=0;m<=3;m++))
    do
      	if [ ${LAST_YR_TS[$m]} -lt 0 ]; then
	    COUPLED_FLAG=0
	fi
    done
    if [ $COUPLED_FLAG -eq 1 ]; then
	echo "-----------------------------------"
	echo "COUPLED RUN: $sim"
	echo "-----------------------------------"
	let "NYRS = ${LAST_YR_TS[0]} - ${FIRST_YR_TS[0]}"
	if [ $NYRS -lt 10 ]; then
	    echo " Too few years for atm. climatology (NYRS=${NYRS})"
	else
	    LAST_YR_CLIMO=${LAST_YR_TS[0]}
	    if [ $NYRS -lt 20 ]; then
		let "FIRST_YR_CLIMO = ${LAST_YR_TS[0]} - 9"
	    else
		if [ $NYRS -lt 40 ]; then
		    let "FIRST_YR_CLIMO = ${LAST_YR_TS[0]} - 19"
		else
		    let "FIRST_YR_CLIMO = ${LAST_YR_TS[0]} - 29"
		fi
		echo " atm climatology ${FIRST_YR_CLIMO[$m]}-${LAST_YR_CLIMO[$m]} (sim length ${FIRST_YR_TS[$m]}-${LAST_YR_TS[$m]})"
		# Update cases file for ESMValTool
		# - delete last case
		# - Add new case
		sed -i '$ d' $ESMVAL_DIR/cases_list
		sed -i "1i $sim ${FIRST_YR_CLIMO[$m]} ${LAST_YR_CLIMO[$m]}" $ESMVAL_DIR/cases_list
		# Run ESMValTool
		$ESMVAL_DIR/esmval_portrait_auto -b -p $NAMELIST
	    fi
	fi
    else
	echo "$sim not a NorESM/CESM coupled experiment."
    fi
done<cases_new
