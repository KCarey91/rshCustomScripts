#! /bin/bash
## Custom sar view to see what might have been causing load at a specific time.
##    12:00:02  AM  ldavg-1  ldavg-5  ldavg-15  %memused  %commit  %swpused  bread/s  bwrtn/s
## Usage:     sars "regex" (sarfile-optional)
##   eg:  sars '^01:.*AM' /var/log/sysstat/sa10   # ( Leave file blank for most recent )

function sars() {
  regex=${1:-"[AP]M"}
  [[ -n $2 ]] && sarfile="-f ${2}" || sarfile=''
  paste <(sar ${sarfile} -q | awk 'NR==3 || /'${regex}'/ { print $1,$2,$5,$6,$7}')\
        <(sar ${sarfile}    | awk 'NR==3 || /'${regex}'/ { print $4,$7,$9 }') \
        <(sar ${sarfile} -r | awk 'NR==3 || /'${regex}'/ {print $5,$9}') \
        <(sar ${sarfile} -S | awk 'NR==3 || /'${regex}'/ {print $5 }') \
        <(sar ${sarfile} -b | awk 'NR==3 || /'${regex}'/ {print $6,$7}' ) \
        <(sar ${sarfile} -n SOCK  | awk 'NR==3 || /'${regex}'/ {print $3,$4,$8}') \
        | awk '{
          if ($3>N) {$3="\033[1;31m"$3"\033[0m"}
            else {$3="\033[1;32m"$3"\033[0m"}
          if ($4>N) {$4="\033[1;31m"$4"\033[0m"}
            else {$4="\033[1;32m"$4"\033[0m"}
          if ($5>N) {$5="\033[1;31m"$5"\033[0m"}
            else {$5="\033[1;32m"$5"\033[0m"}
          {print}}' N=$(grep 'model name' /proc/cpuinfo| wc -l) \
        | column -t
}
