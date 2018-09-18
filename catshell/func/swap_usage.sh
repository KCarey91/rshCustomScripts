#! /bin/bash
## Prints off the top users of swap (VmSwap) along with normal mem usage (VmSize)
##   Usage:  swap_usage  #no args

function swap_usage() {
  { echo "Process VmSize VmSwap" ;
  find /proc -maxdepth 2 -mindepth 2 -name status |
    xargs -n 1 awk '$1 ~ /^(Name|VmSize|VmSwap):/ {printf $2 " "}; END {print ""}' |
    sort -k3rn | head -n 20 ; } 2>/dev/null  | column -t
}
