#! /bin/bash

## Check badboyz.conf and iptables for a blacklisted IP or IPs.
##
##   isblocked IP [IP] [IP] ...
##

function isblocked() {
  grn='\033[1;32m' lgrn='\033[0;32m' red='\033[1;31m' rst='\033[0m'
  #get dem IPs and build an array and regex expression
  if [[ -z $1 ]]
   then echo -e "${grn}IP List (spaced):${lgrn} \c" ; read iplist
   else iplist="$*"
  fi
  declare -a iplist="(${iplist})"
  ipregex="($(for ip in ${iplist[@]} ; do printf "${ip//\./\\.}|"; done)^$)"
  #checkin' in badboyz
  echo -e "${lgrn}Checking ${grn}/nas/wp/conf/lb/blocked-ips/badboyz.conf${rst} : \n"
  nl -ba /nas/wp/conf/lb/blocked-ips/badboyz.conf | egrep "${ipregex}"
  # checkin' in iptables
  echo -e "${lgrn}Checking ${grn}iptables${rst} : \n"
  sudo iptables -nL | egrep "(${ipregex//[()]/}|INPUT|FORWARD|OUTPUT)"
  echo -e "\n${grn}Done with checks.${rst}"
}
