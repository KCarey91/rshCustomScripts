#Author: David T. Noland
#Name: Disk Auditor
#Version: 1.0
#About: This tool will create an audit of live, staging, or both (default) installs for all installs on a given account.

function diskaudit() {

  local description='produces a diskspace audit report for list of installs on given server.\nThis will not execute for distributed sites, but only on sites on the same server.\nExecute ${yellow}waldo${NC} to get a full list of installs by pod/cluster ID.'
  [[ "$@" =~ '--help' ]] || [[ "$@" =~ '-h' ]] && {
    echo -e "${yellow}diskaudit${NC} ${description}\n"
    echo -e "\tdiskaudit [${yellow}install${NC} or ${yellow}list of installs${NC}]"
    return
  }

  #Usage check
  local installs="$@"
  [[ "$@" = "" ]] && {
    echo -e "${red}Usage:${NC} diskaudit [${yellow}install${NC} or ${yellow}list of installs${NC}]"
    echo -e "This will only execute on installs listed on your current pod/cluster."
    echo -e "Execute ${yellow}waldo${NC} to get a full list of installs by pod/cluster ID."
    return 0;
  }

  #Variable definitions
  echo -e "${green}Disk Auditor v1.0${NC}\n"
  echo -e "${yellow}Initializing variables...${NC}"
  local live_du_sum=0
  local live_sum=0
  local staging_du_sum=0
  local stage_sum=0
  local db_live_sum=0
  local db_staging_sum=0
  local DU_LIVE=0
  local DB_LIVE=0
  local DB_STAGE=0
  local TOTAL=0
  local SUM_TOTAL=0
  local WPDB="wp db query --skip-plugins --skip-themes"

  #Prep column totals
  for site in ${installs};
    do {
      echo $(du -s /nas/content/live/${site} | awk '{print $1}') >> live_du.tmp
      echo $(du -s /nas/content/staging/${site} | awk '{print $1}') >> staging_du.tmp
      db_live_tmp=$(sudo mysql -e "SELECT SUM(round(((data_length + index_length) / 1024 / 1024),2)) FROM information_schema.TABLES WHERE table_schema = 'wp_${site}' and TABLE_TYPE='BASE TABLE';" | tail -1)
      [[ ${db_live_tmp} == "NULL" ]] && db_live_tmp=0
      echo ${db_live_tmp} >> db_live.tmp
      db_stage_tmp=$(sudo mysql -e "SELECT SUM(round(((data_length + index_length) / 1024 / 1024),2)) FROM information_schema.TABLES WHERE table_schema = 'snapshot_${site}' and TABLE_TYPE='BASE TABLE';" | tail -1)
      [[ ${db_stage_tmp} == "NULL" ]] && db_stage_tmp=0
      echo ${db_stage_tmp} >> db_staging.tmp
    }
  done

  # recalculate variables
  live_du_sum=$(cat live_du.tmp | awk '{s+=$1} END {print s/1024}')
  live_sum=$(printf "%0.2f" ${live_du_sum})
  staging_du_sum=$(cat staging_du.tmp | awk '{s+=$1} END {print s/1024}')
  stage_sum=$(printf "%0.2f" ${staging_du_sum})
  db_live_sum=$(paste -sd+ db_live.tmp | bc)
  db_staging_sum=$(paste -sd+ db_staging.tmp | bc)
  TOTAL=$(python -c "print (${live_sum}+${stage_sum}+${db_live_sum}+${db_staging_sum})/1024")
  SUM_TOTAL=$(printf "%0.2f" ${TOTAL})
  # Clean tmp Files
  rm live_du.tmp staging_du.tmp db_live.tmp db_staging.tmp

  #Enable sudo MySQL, grab cluster ID, calculate innodb_buffer_pool_size in MB
  sudo mysql -e ""
  local pod=$(wpephp option-get $1 cluster)
  local ibps=$(wp db query "show global variables;" | grep innodb_buffer_pool_size | awk '{print $2}')
  if [ ${ibps} -lt 536870912 ] || [ ${ibps} -eq 536870912 ]
    then local buffer=$(python -c "print $ibps / 1024 / 1024")
    else local buffer=$(python -c "print $ibps / 1024 / 1024 / 1024")
  fi

  echo -e "${teal}Executing disk audit:\n"
# report

  echo -e "Cluster ID: ${yellow}${pod}${NC}"
  if [ ${buffer} -gt 200 ]
    then echo -e "${teal}innodb_buffer_pool_size: ${yellow}${buffer} MB${NC}\n"
  else echo -e "${teal}innodb_buffer_pool_size: ${yellow}${buffer} GB${NC}\n"
  fi

  echo -e "${teal}+---------------------------+------------+-----------+-------------+-------------+"
  echo -e "|        ${NC}Install name${teal}       | ${NC}Production${teal} |  ${NC}Staging${teal}  |     ${NC}wp_ ${teal}    |  ${NC}snapshot_ ${teal} |"
  echo "+---------------------------+------------+-----------+-------------+-------------+"
  for site in ${installs};
    do {
      DU_LIVE=$(du -hsx /nas/wp/www/sites/${site} | awk '{print $1}')
      DB_LIVE=$(sudo mysql -e "SELECT SUM(round(((data_length + index_length) / 1024 / 1024),2)) FROM information_schema.TABLES WHERE table_schema = 'wp_${site}' and TABLE_TYPE='BASE TABLE';" | tail -1)
      [[ ${DB_LIVE} == "NULL" ]] && DB_LIVE=0
      DU_STAGE=$(du -hsx /nas/wp/www/staging/${site} | awk '{print $1}')
      DB_STAGE=$(sudo mysql -e "SELECT SUM(round(((data_length + index_length) / 1024 / 1024),2)) FROM information_schema.TABLES WHERE table_schema = 'snapshot_${site}' and TABLE_TYPE='BASE TABLE';" | tail -1)
      [[ ${DB_STAGE} == "NULL" ]] && DB_STAGE=0
      printf "${teal}|${green} %-26s${teal}|${NC} %-11s${teal}|${NC} %-10s${teal}|${NC} %-8s${teal} MB |${NC} %-9s${teal}MB |\n" ${site} ${DU_LIVE} ${DU_STAGE} ${DB_LIVE} ${DB_STAGE}
    }
    done
  echo "+---------------------------+------------+-----------+-------------+-------------+"
  printf "${teal}|${green} Summary totals: ${NC}%-6s GB${teal} |${NC} %-8s${teal} MB|${NC} %-7s${teal} MB|${NC} %-8s${teal} MB |${NC} %-8s${teal} MB |\n" ${SUM_TOTAL} ${live_sum} ${stage_sum} ${db_live_sum} ${db_staging_sum}
  echo "+---------------------------+------------+-----------+-------------+-------------+"


#  do {
#    DU_LIST_STAGE=$(echo -e "$DU_LIST_STAGE \n$(du -h --max-depth=0 /nas/wp/www/staging/${stage_site} 2>/dev/null)\n")
#    SUM_STAGE=$(echo -e "$SUM_STAGE \n$(du --max-depth=0 /nas/wp/www/staging/${stage_site} 2>/dev/null | awk '{print $1;}')")
#  }
#  done
#  echo -e "$DU_LIST_STAGE" | sort -h; awk '{s+=$1} END {print "Total: "s/1024/1024" GB"}' <<<"$SUM_STAGE"
}
