#! /bin/bash
## Monitor clusters with multiple webheads:
##  Run as root via screen and it will check all webheads + utility + dbmaster
##   and will send an email alert (if email is specified) if it detects:
##      High Load -  Load > Number of CPU cores
##      Replication Lag greater than 1 Seconds_Behind_Master
##      50x errors detected in log (if install is specified)
##
##  usage:
##    webhead-monitor (install) (alert_email)

function webhead-monitor() {
  [[ -n $1 ]] && install=${1} || install=$(pwd|cut -d/ -f5)
  alert_email=$2
  tmp_file='/tmp/.WPE.webhead-monitor-alert'
  rm ${tmp_file} 2>/dev/null
  thiscluster=$(uname -n) thiscluster=${thiscluster#*-} thiscluster=${thiscluster%-*}
  webhead_list=$(egrep -o " (utility|dbmaster|web)-${thiscluster}\S*" /etc/hosts|uniq)
  declare -a webheads=(${webhead_list}) ; unset webhead_list
  cores=$(grep -c 'model name' /proc/cpuinfo)
  logfile="/tmp/monitoring.$(date +%Y-%m-%d).log"
  last_mail_sent=0

  while true; do
    { echo;date; } | tee -a ${logfile}
    for web in ${webheads[@]} ; do
      { response=($(ssh -o StrictHostKeyChecking=no ${web} 'printf "$(uname -n) $(cat /proc/loadavg) Repl:$(mysql -E -e "show slave status" 2>/dev/null | grep -oP "(?<=Seconds_Behind_Master: )[0-9]*") 50x:$(tail -n1000 /var/log/nginx/'${install}'.access.log 2>/dev/null | grep -c "|50[0-9]|")\n"'))

      echo ${response[@]} |
      awk '{
      loadpct=100*$2/N "%"
      if ($2>N) {two="\033[1;31m"$2"\033[0m" ; loadcol="\033[1;31m" }
        else {two="\033[1;32m"$2"\033[0m"; loadcol="\033[1;32m" }
      if ($3>N) {three="\033[1;31m"$3"\033[0m"}
        else {three="\033[1;32m"$3"\033[0m"}
      if ($4>N) {four="\033[1;31m"$3"\033[0m"}
        else {four="\033[1;32m"$4"\033[0m"}
      if ( $7 == "Repl:" ) {seven="--N/A--"}
        else { seven=$7 }
      if ( match($8,"50x:[1-9]") ) { eight="\033[1;31m"$8"\033[0m" }
        else { eight="\033[1;32m"$8"\033[0m" }
      {printf "%-16s(%s%6.2f\033[0m%%) %s %s %s\tRun/Tot:%s\t%-10s%s\n",$1,loadcol,100*$2/N,two,three,four,$5,seven,eight,$8}}' N=${cores}

      [[ ${response[1]%.*} -ge ${cores} ]] && echo "High Load! I can't even." >> ${tmp_file}
      [[ ${response[6]#*:} -gt 3 ]]     && echo "OMG.  Replication lag." >> ${tmp_file}
      [[ ${response[7]#*:} -gt 0 ]]     && echo "Ermagerd. 50x errors for ${install}." >> ${tmp_file} ; } &
    done  | sort | tee -a ${logfile}
    if [[ -f ${tmp_file} && $(($(date +%s) - ${last_mail_sent})) -gt 600 && -n ${alert_email} ]] ; then
      echo -e "\033[1;31mSending Alert Message! \033[0m"
      { echo "Server says: $(cat ${tmp_file})" ; cat ${logfile} | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" ; }  |
         mail -s "${install} Monitoring Alert - $(date)" ${alert_email}
      last_mail_sent=$(date +%s)
    fi
    rm ${tmp_file} 2>/dev/null
    tac ${logfile} | head -n 200 | tac > ${logfile}.tmp
    mv -f ${logfile}.tmp ${logfile}
    sleep 30
  done
}
