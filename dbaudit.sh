#Author: David T. Noland
#Name: Datbase Auditor
#Version: 2.1
#About: This tool will create an audit of live, staging, or both (default) installs for all installs on a given account.

function dbaudit() {

  local description='produces a database audit report for list of installs on given server.\nThis will not execute for distributed sites, but only on sites on the same server.\nExecute ${yellow}waldo${NC} to get a full list of installs by pod/cluster ID. ${red}Must${NC} be run from ${yellow}screen${NC}.'
  [[ "$@" =~ '--help' ]] || [[ "$@" =~ '-h' ]] && {
    echo -e "${yellow}dbaudit${NC} ${description}\n"
    echo -e "\tdbaudit [${yellow}install${NC} or ${yellow}list of installs${NC}]"
    return
  }

  #Usage check
  local installs="$@"
  [[ "$@" = "" ]] && {
    echo -e "${red}Usage:${NC} dbaudit [${yellow}install${NC} or ${yellow}list of installs${NC}]"
    echo -e "This will only execute on installs listed on your current pod/cluster."
    echo -e "Execute ${yellow}waldo${NC} to get a full list of installs by pod/cluster ID."
    return 0;
  }

  #Variable definitions
  echo -e "${green}Database Auditor v1.0${NC}\n"
  echo -e "${yellow}Initializing variables...${NC}"
  local live=""
  local stage=""
  local total_live=$(sudo mysql -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024 , 2) AS 'Size (GB)' FROM information_schema.TABLES WHERE table_schema LIKE 'wp_%';" | tail -1)
  local total_stage=$(sudo mysql -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024 , 2) AS 'Size (GB)' FROM information_schema.TABLES WHERE table_schema LIKE 'snapshot_%';" | tail -1)
  local total_db=$(sudo mysql -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024 , 2) AS 'Size (GB)' FROM information_schema.TABLES WHERE table_schema LIKE 'wp_%' or table_schema LIKE 'snapshot_%';" | tail -1)
  local ibps=$(sudo mysql -e "show global variables;" | grep innodb_buffer_pool_size | awk '{print $2}')
  local buffer=$(python -c "print ${ibps} / 1024 / 1024 / 1024")

  #Print table header row
  echo "+---------------+------------+------------+"
  echo -e "| Install       |     ${green}wp_${NC}    |  ${green}snapshot_${NC} |"
  echo "+---------------+------------+------------+"
  for site in ${installs}
    do {
      live=$(sudo mysql -e "SELECT SUM(round(((data_length + index_length) / 1024 / 1024),2)) FROM information_schema.TABLES WHERE table_schema='wp_${site}' and TABLE_TYPE='BASE TABLE';" | tail -1)
      [[ ${live} == NULL ]] && live=0
      stage=$(sudo mysql -e "SELECT SUM(round(((data_length + index_length) / 1024 / 1024),2)) FROM information_schema.TABLES WHERE table_schema='snapshot_${site}' and TABLE_TYPE='BASE TABLE';" | tail -1)
      [[ ${stage} == NULL ]] && stage=0
      printf "|${green}%-15s${NC}| %-7s MB | %7s MB |\n" ${site} ${live} ${stage}
    }
    done
  echo "+---------------+------------+------------+"
  [[ ${total_live} == NULL ]] && total_live=0
  [[ ${total_stage} == NULL ]] && total_stage=0
  echo -e "${green}Total ${yellow}wp_${green} usage: ${NC}${total_live} GB"
  echo -e "${green}Total ${yellow}snapshot_${green} usage: ${NC}${total_stage} GB"
  echo -e "${green}Total ${yellow}DB${green} usage: ${NC}${total_db} GB"
  [[ ${ibps} -gt 536870912 ]] && echo -e "${green}innodb_buffer_pool_size: ${yellow}${buffer} GB${NC}";
}
