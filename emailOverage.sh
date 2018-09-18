## Name: mail-tool
## Desc: Various sent and queued mail tools
## Vers: 1.0.0
# Color definitions
bold='\e[1m'
unbold='\e[0m'
red='\x1b[0;31m'
yellow='\x1b[0;33m'
teal='\x1b[0;36m'
purple='\x1b[0;35m'
nc='\x1b[0m'
# Shortcut alias
alias mt='mail-tool'
# Usage display function
function mt_usage()
{
	echo -e "USAGE:\n"
	echo -e "\t${yellow}${bold}mail-tool queue list (--sort)${unbold}${nc}\n"
	echo -e "\t\tShow all queued email in an easy to read format. Sorting takes longer.\n"
	echo -e "\t${yellow}${bold}mail-tool queue headers [header name]${unbold}${nc}\n"
	echo -e "\t\tShow freqency of data in all queued mail for a given header.\n"
	echo -e "\t${yellow}${bold}mail-tool queue delete [install|hash]${unbold}${nc}\n"
	echo -e "\t\tDelete all queued emails from given install name or hash.\n"
	echo -e "\t${yellow}${bold}mail-tool sent count (--top)${unbold}${nc}\n"
	echo -e "\t\tShow sent email counts for each install. Sorting takes longer.\n"
	echo -e "\t${yellow}${bold}mail-tool sent posts (--nginx) (--yesterday)${unbold}${nc}\n"
	echo -e "\t\tShow POST data from access logs. --nginx generates nginx block code, --yesterday uses yesterday's logs\n"
	echo -e "\t${yellow}${bold}mail-tool [enable|disable] [install] (--permanent)${unbold}${nc}\n"
	echo -e "\t\tEnable or disable a site to send email. --permanent requires manual removal.\n"
}
# Main function
function mail-tool()
{
	echo ""
	if [[ -z $1 ]]; then mt_usage; return 0; fi
	if [[ $1 == "queue" || $1 == "q" ]]
	then
		sudo cat /etc/cluster-id >/dev/null
		if [[ $2 == "list" || $2 == "l" ]]
		then
			printf "+------------+----------------+---------------------------+---------------------------+-------------------------------------+\n"
			printf "| QUEUE ID   | INSTALL        | FROM                      | TO                        | SUBJECT (TRUNCATED)                 |\n"
			printf "+------------+----------------+---------------------------+---------------------------+-------------------------------------+\n"
			hashes=$(ls /nas/content/live/ | while read i; do echo "$i $(echo -n "$i" | sha1sum | awk {'print $1'})"; done)
			if [[ $3 == "--sort" || $3 == "-s" ]]
			then
				ending="sort -k4"
			else
				ending="cat"
			fi
			mailq | egrep -o "^[A-Z0-9]{9,11}" | while read i; do
				msg=$(sudo postcat -q $i 2>/dev/null)
				if [[ ${msg} == "" ]]; then continue; fi
				msgHash=$(echo "${msg}" | grep "^X-WPE-Internal-ID:" | awk {'print $2'})
				if [[ ${msgHash} == "d9543b1178b77ff83fc79e803a4ef08eab669c58" ]]
				then
					msgInstall="SMTP"
				else
					msgInstall=$(echo "${hashes}" | grep "${msgHash}" | awk {'print $1'})
				fi
				msgTo=$(echo "$msg" | grep "^To:" | awk {'print $2'})
				msgFrom=$(echo "$msg" | grep "^From:" | awk {'print $2'} | sed 's/<//g' | sed 's/>//g')
				msgSubject=$(echo "$msg" | grep "^Subject:" | sed 's/Subject: //g')
				printf "| %-10s | %-14s | %-25s | %-25s | %-35s |\n" "${i}" "${msgInstall}" "${msgFrom:0:25}" "${msgTo:0:25}" "${msgSubject:0:35}";
			done | ${ending}
			printf "+------------+----------------+---------------------------+---------------------------+-------------------------------------+\n"
			return 0
		elif [[ $2 == "delete" || $2 == "d" ]]
		then
			if [[ -z $3 ]]; then mt_usage; return 0; fi
			if [[ ${#3} == 40 ]]
			then
				msgHash=$3
			else
				msgHash=$(echo -n $3 | sha1sum | awk {'print $1'})
			fi
			echo -e "This will run the following:\n"
			mailq | egrep -o "^[A-Z0-9]{9,11}" | while read i; do
				if [[ $(sudo postcat -q $i | grep "^X-WPE-Internal-ID: ${msgHash}") != "" ]]
				then
					echo -e "${red}sudo postsuper -d $i ${nc}"
				fi
			done
                        echo -en "\nConfirm (y/n)?   "
                        read x
                        if [[ ${x} == "y" || ${x} == "yes" ]]
                        then
				mailq | egrep -o "^[A-Z0-9]{9,11}" | while read i; do
					if [[ $(sudo postcat -q $i | grep "^X-WPE-Internal-ID: ${msgHash}") != "" ]]
					then
						sudo postsuper -d $i
                        	        fi
				done
			else
				echo -e "Aborting! No messages deleted.\n"
			fi
			return 0
		elif [[ $2 == "headers" || $2 == "header" || $2 == "h" ]]
		then
			if [[ -z $3 ]]; then mt_usage; return 0; fi
			mailq | grep www-data | awk {'print $1'} | while read i; do
				sudo postcat -q $i | grep -i "^${3}:" | awk -F":" {'print $2'}
			done | sort | uniq -c | sort -n
			echo ""
			return 0
		else
			mt_usage
			return 1
		fi
	elif [[ $1 == "sent" || $1 == "s" ]]
	then
		if [[ $2 == "counts" || $2 == "count" || $2 == "c" ]]
		then
			printf "+----------------------+---------+------------------------------+------------------------------------------+\n"
			printf "| INSTALL              |  COUNT  | LATEST EMAIL SENT            |  HASH                                    |\n"
			printf "+----------------------+---------+------------------------------+------------------------------------------+\n"
			if [[ $3 == "--tops" || $3 == "-t" ]]
			then
				ending="sort -nk4 | tail"
			else
				ending="cat"
			fi
			for i in $(ls /nas/content/live/); do
				iHash=$(echo -n ${i} | sha1sum | awk {'print $1'})
				countFile="/var/spool/proxsmtp/count.${iHash}"
				if [[ ! -e ${countFile} ]]; then continue; fi
				if [[ -e /var/spool/proxsmtp/disable.${iHash} ]]
				then
					echo -e "$(printf "| %-47s | %7s | %28s | %25s |\n" "${red}${bold}${i}${unbold}${nc}" \
					"$(wc -l ${countFile} | awk {'print $1'})" "$(date -d @$(tail -1 ${countFile}))" "${iHash}")"
				else
					echo -e "$(printf "| %-20s | %7s | %28s | %25s |\n" "${i}" \
					"$(wc -l ${countFile} | awk {'print $1'})" "$(date -d @$(tail -1 ${countFile}))" "${iHash}")"
				fi
			done | ${ending}
			printf "+----------------------+---------+------------------------------+------------------------------------------+\n"
			echo -e "\nNotes: Mail counts are since last reboot ($(uptime -s))."
			echo -e "\n       ${red}${bold}Bold red installs${unbold}${nc} are disabled from sending mail.\n"
			return 0
		elif [[ $2 == "posts" || $2 == "post" || $2 == "p" ]]
		then
			if [[ $3 == "--yesterday" || $3 == "-y" || $4 == "--yesterday" || $4 == "-y" ]]
			then
				xFile='.1'
			else
				xFile=''
			fi
			echo -e "The following POST URLs have been hit at least 500 times:\n"
			ls /nas/content/live/ | egrep -v "secure|apache-queue" | while read i; do
				showInstall="false"
				if ! [[ -e /var/log/nginx/$i.access.log${xFile} ]]
				then
					continue
				fi
				grep POST /var/log/nginx/$i.access.log${xFile} | egrep -v "wp-cron|login|xmlrpc|admin-ajax" \
				| awk -F"|" {'print $4" "$10'} | awk {'print "http://"$1 $3'} | sort | uniq -c | sort -n \
				| awk '$1 > 500 {print $0}' | while read url; do
					if [[ $showInstall == "false" ]]
					then
						echo -e "\t${yellow}${bold}$i:${unbold}${nc}\n"
						showInstall="true"
					fi
					echo -e "\t\t${teal}${bold}${url}${unbold}${nc}"
					topAgent=$(grep "$(echo $url | cut -d'/' -f 4-)" /var/log/nginx/$i.apachestyle.log${xFile} \
					| awk -F"\"" {'print $6'} | sort | uniq -c | sort -n | tail -1)
					echo -e "\n\t\t\t${yellow}${bold}${topAgent}${unbold}${nc}\n"
					if [[ $3 == "--nginx" || $3 == "-n" || $4 == "--nginx" || $4 == "-n" ]]
					then
						urlPath=$(echo $url | cut -d'/' -f 4-)
						echo -e "${purple}${bold}"
						echo "-------------------------------------------------------------------------"
						echo -e "# Blocking user agent from exploiting unsecured form for spam -dmiller\n"
						echo 'set $block_form "0";'
						echo ''
						echo -n 'if ($request_uri ~* "^/'
						echo -n ${urlPath}
						echo '") { set $block_form "1"; }'
						echo -n 'if ($http_user_agent = "'
						echo -n "$(printf "%s" "$(echo ${topAgent} | cut -d' ' -f2-)")"
						echo '") { set $block_form "$block_form:1"; }'
						echo ''
						echo 'if ($block_form = "1:1") { return 403; }'
						echo "-------------------------------------------------------------------------"
						echo -e "${unbold}${nc}"
					fi
				done
			done
			echo ""
			if [[ $3 == "--nginx" || $3 == "-n" || $4 == "--nginx" || $4 == "-n" ]]
			then
				echo -e "${red}${bold}Any NGINX rewrite code provided for blocking User Agent is a BEST GUESS."
				echo -e "Please be sure to sanity check it to make sure you're not blocking something important.${unbold}${nc}"
			fi
			return 0
		else
			mt_usage
			return 1
		fi
	elif [[ $1 == "enable" ]]
	then
		if [[ -z $2 ]]; then mt_usage; return 0; fi
		if [[ ! -d /nas/content/live/$2/ ]]
		then
			echo -e "Install \"$2\" does not exist on this server.\n"
			return 1
		fi
		iHash=$(echo -n $2 | sha1sum | awk {'print $1'})
		if [[ -e /var/spool/proxsmtp/disable.${iHash} ]]
		then
			sudo rm -v "/var/spool/proxsmtp/disable.${iHash}" && echo -e "Re-enabled install \"$2\" for sending email successfully.\n"
			return 0
		else
			echo -e "Install \"$2\" is not currently disabled from sending email.\n"
			return 1
		fi
	elif [[ $1 == "disable" ]]
	then
		if [[ -z $2 ]]; then mt_usage; return 0; fi
		if [[ ! -d /nas/content/live/$2/ ]]
		then
			echo -e "Install \"$2\" does not exist on this server.\n"
			return 1
		fi
		iHash=$(echo -n $2 | sha1sum | awk {'print $1'})
		if [[ -e /var/spool/proxsmtp/disable.${iHash} ]]
		then
			echo -e "Install \"$2\" is already disabled from sending email.\n"
			return 1
		else
			sudo touch /var/spool/proxsmtp/disable.${iHash} && echo -e "Disabled install \"$2\" from sending email successfully.\n"
			if [[ $3 == "--permanent" || $3 == "--perm" || $3 == "-p" ]]
			then
				return 0
			else
				sudo chown proxsmtp: /var/spool/proxsmtp/disable.${iHash}
				return 0
			fi
		fi
	else
		mt_usage; return 1
	fi
}
