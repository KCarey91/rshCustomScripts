#!/bin/bash

## Check pods for available disk space before performing migrations, etc.
##  Usage:
##    pod-space 12345 {40000..40010} 43210

function pod-space() {
  ssh_user=$(grep -v "#" ~/redshell/sshuser)
  for i in $* ; do
    echo -e "${i} $(ssh -l ${ssh_user} -o StrictHostKeyChecking=no -o ConnectTimeout=1 pod-${i}.wpengine.com df -h /nas | grep -v Filesystem)"
  done 2>/dev/null |
  awk 'BEGIN {printf "\033[1;35m%-10s\033[4;35m%-10s%-10s%-s\033[0m\n","Pod #","DiskSize","Avail","Used%"} ;
     {pct=$6
     if (match($6,"[89][0-9]%")) pct="\033[1;31m"pct"\033[0m"
     if (match($6,"[67][0-9]%")) pct="\033[1;33m"pct"\033[0m"
     if (match($6,"[0-5][0-9]%")) pct="\033[1;32m"pct"\033[0m"
     printf "\033[1;35m%-10s\033[0;35m%-10s%-10s%-10s\033[0m\n",$1,$3,$5,pct}'
}
