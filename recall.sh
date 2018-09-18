## Name: recall.sh
## Date: May 8, 2018
## Desc: Check sar, recap, and nginx logs to find the likely culprit of a server crash

# Colors

yellow='\x1b[0;33m'
nc='\x1b[0m'

function recall()
{
	echo ""

	recapFile=$(find /var/log/recap/ -maxdepth 1 -mindepth 1 -type f -name "ps_*" -not -name "ps_daily_*" -exec wc -l {} \; \
		| sort -n | tail -1 | awk {'print $2'})

	echo -e "\t${yellow}Recap file being used:${nc}\n\n\t     ${recapFile}\n"

	topProcs=$(cat "${recapFile}" | egrep -v "\[" | sed 's/\\_//g; s/|//g' | tr -s ' ' | cut -d' ' -f11- \
		| while read p; do printf "%-100s\n" "${p:0:100}"; done | sort | uniq -c | sort -n | tail -5)

	echo -e "\t${yellow}Top Processes:${nc}\n"

	echo -e "${topProcs}\n" | sed 's/^/\t/g'

	topProcName="$(echo -e "${topProcs}" | tail -1 | awk {'print $2'})"

	if [[ "${topProcName}" == "/usr/sbin/apache2" ]]
	then
		echo -e "\t${yellow}Top Access Logs:${nc}\n"

		topTime="$(date "+%d/%b/%Y"):$(grep '/usr/sbin/apache2' "${recapFile}" | awk {'print $9'} | sort | uniq -c | sort -n | tail -1 | awk {'print $2'})"

		topLogs=$(egrep -vH "\.(png|jpg|jpeg|gif|ico|svg|js|css|tiff|tff|txt)" /var/log/nginx/*.access.log | egrep "${topTime}:.." \
			| awk -F":" {'print $1'} | egrep -v "*-secure|secure.access|apache-queue" | sort | uniq -c | sort -n | tail -5)

		echo -e "${topLogs}\n" | sed 's/^/\t/g'

		echo -e "\t${yellow}Top Install Activity:${nc}\n"

		topLog=$(echo -e "${topLogs}" | tail -1 | sed 's/\.access\./\.apachestyle\./g' | awk {'print $2'})

		problemInstall=$(echo -e "${topLog}" | awk -F"/" {'print $5'} | awk -F"." {'print $1'} | awk -F"-" {'print $1'})

		timeLog=$(egrep "${topTime}:.." "${topLog}" | egrep -v "\.(png|jpg|jpeg|gif|ico|svg|js|css|tiff|tff|txt)")

		echo -e "${timeLog}\n" | awk '$1 != "" {print "\t"$4"\t"$1"\thttp://"$2 $7}' | sed 's/\[//g' | column -t | sed 's/^/\t     /g'

		problemIP=$(echo -e "${timeLog}" | awk {'print $1'} | sort | uniq -c | sort -n | tail -1 | awk {'print $2'})

		problemIPcount=$(echo -e "${timeLog}" | awk {'print $1'} | sort | uniq -c | sort -n | tail -1 | awk {'print $1'})

		problemURLs=$(echo -e "${timeLog}" | awk {'print "http://"$2 $7'} | sort | uniq -c | sort -n | tail -1)

		problemURL=$(echo -e "${problemURLs}" | awk {'print $2'})

		problemURLcount=$(echo -e "${problemURLs}" | awk {'print $1'})

		problemUAs=$(egrep "${topTime}:.." "${topLog}" | egrep -v "\.(png|jpg|jpeg|gif|ico|svg|js|css|tiff|tff|txt)" | awk -F"\"" {'print $6'} | sort | uniq -c | sort -n | tail -1)

		problemUA=$(echo -e "${problemUAs}" | tr -s ' ' | cut -d' ' -f3-)

		problemUAcount=$(echo -e "${problemUAs}" | awk {'print $1'})

		echo ""

		echo -e "\t${yellow}   Install:${nc} ${problemInstall}"
		echo
		echo -e "\t${yellow}        IP:${nc} ${problemIP} (${problemIPcount})"
		echo -e "\t${yellow}       URL:${nc} ${problemURL} (${problemURLcount})"
		echo -e "\t${yellow}      Time:${nc} ${topTime}"
		echo
		echo -e "\t${yellow}User Agent:${nc} ${problemUA} (${problemUAcount})"


	else

		grep -- "${topProcName}" "${recapFile}"

	fi

	echo ""
}
