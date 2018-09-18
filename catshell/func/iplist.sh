#! /bin/bash

## Prints off a list of IPs added to the server and marks dedicated IP addresses in red.
##   usage:  iplist               (no arguments)

function iplist() {
   declare -a ip_addresses=($(ip a | grep global | awk '{printf "%s ",$2}')) # 1.2.3.4/24
   declare -a dedicated_ip_addresses=($(egrep "listen.*([0-9]{1,3}\.){3}[0-9]" /nas/wp/conf/lb/sites/*.conf | awk '{printf "%s ",$3}')) # 1.2.3.4;
   for ip in ${ip_addresses[@]}; do
     if [[ ${dedicated_ip_addresses[@]} =~ ${ip%/*}  ]] ; then
       user_file=$(grep -l ${ip%/*} /nas/wp/conf/lb/sites/*)
       user_file=${user_file##*/}
       user_file=${user_file%.conf}
       echo -e "\033[1;31mDedi:\t\033[0;31m${ip%/*}\t\033[1;31m${user_file}\033[0m"
     else echo -e "\033[1;32mShrd:\t\033[0;32m${ip%/*}\033[0m"
     fi
   done
   unset user_file ip_addresses dedicated_ip_addresses
}
