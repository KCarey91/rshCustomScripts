#! /bin/bash
## It's the 'w' command with a capital 'W'
##     Usage:  W   or  wtf
##
## Loads more information at a glance:
##
##  LVL   PTS    PID    USER               CWD                IDLE   IP            CMD
##  LVL = Access level.  (ROOT/TOPS/L3/L2/L1) Color coded.
##  PTS/PID = Info about the terminal session
##  USER = Who's logged in
##  CWD = What directory are they in?
##  IDLE = How long since they did stuff?
##  IP =  Not so useful now that everyone is going through bastion servers.
##  CMD = What command are they running right now? (if any)

W() {
  ptslist=($(w -h | awk '{print $2}' | tr '\n' ' '))
  mytty=$(tty)
  mytty=${mytty#/dev/}
  declare -A pid user cwd idle ip cmd group
  { echo -e "\E[01mLVL\E[0m@PTS@PID@USER@CWD@IDLE@IP@CMD"
  for pts in ${ptslist[@]} ; do
    pid[${pts}]=$(ps faux | grep "${pts}.*bas[h]"| grep -v $$ | tail -n1 |awk '{print $2}')
    [[ ${pts} == ${mytty} ]] && pid[${pts}]=$$
    user[${pts}]=$(grep -aoP '(?<=LOGNAME=)[a-z_.]+' /proc/${pid[${pts}]}/environ 2>/dev/null)
    if [[ ${user[${pts}]} == "root" ]] ; then
       user[${pts}]="${user[${pts}]}($(grep -aoP '(?<=SUDO_USER=)[a-z_]+' /proc/${pid[${pts}]}/environ 2>/dev/null))"
    fi
    if [[ -z ${user[${pts}]} ]] ; then
       user[${pts}]=$(who | grep ${pts} | awk '{print $1}')
    fi
    cwd[${pts}]=$(readlink -e /proc/${pid[${pts}]}/cwd)
    wline=($(w|grep ${pts}))
    idle[${pts}]=${wline[4]}
    ip[${pts}]=${wline[2]%%:*}
    cmd[${pts}]=${wline[@]:7}
    groups=$(groups ${user[${pts}]%%\(*})
    if [[ ${groups} =~ root ]] ; then
      group[${pts}]="\E[31mROOT\E[0m"
    elif [[ ${groups} =~ techops ]] ; then
      group[${pts}]="\E[32mTOPS\E[0m"
    elif [[ ${groups} =~ l3 ]]; then
      group[${pts}]="\E[36mL3\E[0m"
    elif [[ ${groups} =~ l2 ]]; then
      group[${pts}]="\E[35mL2\E[0m"
    elif [[ ${groups} =~ l1 ]]; then
      group[${pts}]="\E[33mL1\E[0m"
    else
      group[${pts}]="\E[30m??\E[0m"
    fi
    echo -e "${group[${pts}]}@${pts:-'?'}@${pid[${pts}]:-'?'}@${user[${pts}]:-'?'}@${cwd[${pts}]:-'?'}@${idle[${pts}]:-'?'}@${ip[${pts}]:-'?'}@${cmd[${pts}]:-'?'}"
  done ; } | column -t -s@
}

# For backwards compatibility.
alias wtf=W
