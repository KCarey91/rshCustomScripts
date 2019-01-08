#!/bin/bash
#Author: Daragh Lowe
#Date: 28/11/17
#Desc: Script to parse aws slow logs from the table and output in a format readable by pt-query-digest

function aws_slow {
	# Color definitions
	bold='\e[1m'
	unbold='\e[0m'
	red='\x1b[0;31m'
	yellow='\x1b[0;33m'
	teal='\x1b[0;36m'
	purple='\x1b[0;35m'
	nc='\x1b[0m'

	#Define variables
	logfile=$1
	outfile=/var/tmp/slow_log.out

	#Print usage details to screen
	function print_help {
		echo -e "USAGE:\n"
		echo -e "\t${bold}Dump the mysql.slow_log to a file and run this script against it (example below uses todays date):${unbold}"
		echo -e "\t\tdate_now=\$(date +%Y-%m-%d) && sudo mysql -se \"SELECT * FROM slow_log WHERE start_time LIKE '\${date_now}%'\" mysql > ~/mysql_slow.out\n"
		echo -e "\t${bold}Run this script against the outputted file:${unbold}"
		echo -e "\t\taws_slow ~/mysql_slow.out"
	}

	#Some sanity checks to see if the correct cli args were entered
	if [[ -z "${1}" ]] || [[ $1 == "--help" ]];then
		print_help
		return 1
	fi

	#Check if the logfile exists 
	if [ ! -f ${logfile} ];then
		echo -e "\nThe logfile you specified doesn't exist!\n"
		print_help
		return 1
	fi	

	#Check if the logfile is empty
	if [ ! -s ${logfile} ];then
		echo -e "\nThe logfile you specifed is empty!\n"
		print_help
		return 1
	fi
	
	#Check if an old output file exists and delete if so
	if [ -f "${outfile}" ];then
		rm -v $outfile
	fi
	
	
	#Loop through the log file and write to a new log file in a format understandable by pt-query-digest
	echo -e "\n${teal}Converting log file format (tail /var/tmp/slow_log.out to see progress)...${nc}\n"
	exec 3<&0
	exec 0<$logfile
	while read line
	do 
		DATE=$(echo "$line" | awk '{print $1}')
		TIME=$(echo "$line" | awk '{print $2}')
		USER=$(echo "$line" | awk '{print $3}')
		HOST=$(echo "$line" | awk '{print $5}' | sed 's/\[//g' | sed 's/\]//g')
		QUERYTIME_MIN=$(echo "$line" | awk '{print $6}' | cut -f2 -d':')
		QUERYTIME_SEC=$(echo "$line" | awk '{print $6}' | cut -f3 -d':')
		QUERYTIME=$(echo "(${QUERYTIME_MIN} * 60) + $QUERYTIME_SEC" | bc)
		LOCKTIME=$(echo "$line" | awk '{print $7}')
		ROWSSENT=$(echo "$line" | awk '{print $8}')
		ROWSEXAM=$(echo "$line" | awk '{print $9}')
		DB=$(echo "$line" | awk '{print $10}')
		QUERY=$(echo "$line" | cut -f11)
		echo "# Time: ${DATE}T${TIME}" >> $outfile
		echo "# User@Host: ${USER} @ ${HOST} []" >> $outfile
		echo "# Query_time: ${QUERYTIME}  Lock_time: ${LOCKTIME}  Rows_sent: ${ROWSSENT}  Rows_examined: ${ROWSEXAM}" >> $outfile
		echo "use ${DB};" >> $outfile
		echo "${QUERY};" >> $outfile
	done
	exec 0<&3
	echo "Running pt-query-digest, this may take a while..."
	pt-query-digest "${outfile}"
}
