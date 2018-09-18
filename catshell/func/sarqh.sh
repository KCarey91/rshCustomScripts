#! /bin/bash
## Similar to the 'sarq' command in that it prints off load averages
##  from 'sar -q', colorized red/green for high/normal loads.
## This one will check for historical problems from the last 5 days and
##  only prints off the times where the load was higher than num CPU cores.
## This is by no means pretty, but it works.

function sarqh() {
  echo -e "Periods of High Load: runq-sz plist-sz ldavg-1 ldavg-5 ldavg-15"
  [[ -n $1 ]] && days=$1 || days=8
  for i in $(seq 0 ${days}|tac)
   do d=$(date --date="${i} days ago" "+%d")
    echo -e "==:: $(date --date="${i} days ago" "+%Y/%m/%d %H:%M:%S") ::=="
    sar -q -f /var/log/sysstat/sa${d}|
      awk 'BEGIN {max1=0;max5=0;max15=0} ;
      $5 ~ /[0-9]\.[0-9][0-9]/ {if ($5>max1) {max1=$5}
       if ($6>max5) {max5=$6}
       if ($7>max15) {max15=$7}
       if ($5>N) {five="\033[1;31m"$5"\033[0m"}
        else {five="\033[1;32m"$5"\033[0m"}
       if ($6>N) {six="\033[1;31m"$6"\033[0m"}
        else {six="\033[1;32m"$6"\033[0m"}
       if ($7>N) {seven="\033[1;31m"$7"\033[0m"}
        else {seven="\033[1;32m"$7"\033[0m"}
       if ($5>N || $6>N || $7>N)
      {printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n",$1,$2,$3,$4,five,six,seven}};
      END {print "AVG:\t",max1,"\t",max5,"\t",max15}' N=$(grep 'model name' /proc/cpuinfo| wc -l)
  done
}
