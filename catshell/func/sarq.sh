#! /bin/bash

## Prints off the results of sar -q (load averages) with colorized output
##  If load > number of CPU cores, load avg is red.
##  If load < number of CPU cores, load avg is green.

function sarq() {
  sar -q |
    awk '{
      if ($5>N) {five="\033[1;31m"$5"\033[0m"}
        else {five="\033[1;32m"$5"\033[0m"}
      if ($6>N) {six="\033[1;31m"$6"\033[0m"}
        else {six="\033[1;32m"$6"\033[0m"}
      if ($7>N) {seven="\033[1;31m"$7"\033[0m"}
        else {seven="\033[1;32m"$7"\033[0m"}
      {printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n",$1,$2,$3,$4,five,six,seven}}' N=$(grep 'model name' /proc/cpuinfo| wc -l)
}
