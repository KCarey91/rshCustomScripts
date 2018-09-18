#! /bin/bash

## Print off some historical memory usage information.
##  A less detailed adaptation of sarqh, mostly used for the usage_report function.

function sarrh() {
  echo -e "Periods of High Memory: runq-sz plist-sz ldavg-1 ldavg-5 ldavg-15"
  [[ -n $1 ]] && days=$1 || days=8
  for i in $(seq 0 ${days}|tac)
   do d=$(date --date="${i} days ago" "+%d")
    echo -e "\033[1;37m==:: $(date --date="${i} days ago" "+%Y/%m/%d %H:%M:%S") ::==\033[0m"
    sar -r -f /var/log/sysstat/sa${d}|egrep "(kbmemfree|Average:)"
    sar -r -f /var/log/sysstat/sa${d}|egrep -v "(Average|kbmemfree)"|
      awk 'BEGIN {commitmax=0;commitmin=100;};
        $1 ~ /[0-9][0-9]:/ {
          if ($9 < commitmin) {commitmin=$9}
          if ($9 > commitmax) {commitmax=$9}
        }
        END {
          print "MinCommit%: ",commitmin,"   MaxCommit%: ", commitmax
        }'
  done
}
