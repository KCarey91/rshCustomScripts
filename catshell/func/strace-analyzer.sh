#! /bin/bash
## === Under Construction ===
##  After running an strace, this will look through the output file for
##   common things that cause problems/slow loading times/etc.
##  Currently checks:
##    * MySQL Queries being running
##    * Top files performing MySQL Queries
##    * Top files being read by the process
##    * Outbound connections (connect)

function strace-analyzer() { grn='\033[1;32m' rst='\033[0m'
  [[ -f $1 ]] && strace_file=$1 || echo -e "\033[1;33mProvide a filename: \033[0;33m strace-analyzer <FILE>\033[0m"
  [[ -n $2 ]] && head_length=$2 || head_length=10
  if [[ $strace_file ]] ; then
    echo -e "\n${grn}Top Queries:${rst}"
      grep -oP "SELECT.+(?=/\*)" ${strace_file}|sed 's|\\[nt]| |g'|sort|uniq -c|sort -rn|head -n $head_length
    echo -e "\n${grn}Top Files/Lines performing Queries:${rst}"
      grep SELECT ${strace_file} |
      grep -oP '(?<=\] in \[).*(?=\] \*/)' |
      sort | uniq -c | sort -rn | head -n $head_length
    echo -e "\n${grn}Top .php files opened:${rst}"
      grep -oP "(?<=open\(\")[^\"]*" ${strace_file}  | sort | uniq -c | sort -rn | head -n $head_length
    echo -e "\n${grn}Top outbound connections::${rst}"
     grep 'connect(' _wpeprivate/strace.log | grep -oP '(?<=(inet_addr\("|AF_INET6, "))[\w.:]*' | sort | uniq -c | sort -rn| head -n $head_length
  fi
}
