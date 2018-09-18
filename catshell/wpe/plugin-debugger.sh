#! /bin/bash

## This will disable plugins one at a time on a site and curl the site to check the response code.
## It will also tail the error log in the background while deactivating and busts cache when curling.
## Adapted from the one-liners here:
##   http://supportwiki.wpengine.com/deactivate-all-plugins-without-losing-auth-keys-etc/


function plugin-debugger() {
  install=$(pwd|cut -d/ -f5)
  unset staging
  [[ $(pwd|cut -d/ -f4) == staging ]] && staging=".staging"
  echo "${BRIGHT}${RED}This will deactivate all plugins one at a time and perform curl tests for the ${NORMAL}${RED}${install} - $(pwd|cut -d/ -f4) ${BRIGHT} install.${NORMAL}"
  echo "${BRIGHT}${RED}Make sure you have permission to do this or it's on a staging install.${NORMAL}"
  read -p "Continue? "
  if [[ ${REPLY:0:1} =~ [Yy] ]] ; then
    myip="($(ip a | grep global | awk '{printf "%s|",$2}')127.0.0.1)"
    cache='_wpeprivate/active_plugins.txt'
    install=$(pwd|cut -d/ -f5)
    wp plugin list --status=active --field=name > ${cache}
    ( tail --pid=$$ -n0 -F /var/log/apache2/${install}.error.log | egrep "${myip}" ) & tail_pid=$!
    for i in `wp plugin list --status=active --field=name` ; do
      wp plugin deactivate ${i}
      sleep 1;
      curl -sIL "http://${install}${staging}.wpengine.com/?plugin_deactivated=${i}" | egrep '(HTTP|Location)'
    done
    wp plugin activate $(cat ${cache})
    rm ${cache} ; kill $tail_pid
  else
    echo "${BRIGHT}${CYAN}Quitting and doing nothing.${NORMAL}"
  fi
}

function plugin-debugger-network() {
  install=$(pwd|cut -d/ -f5)
  unset staging
  [[ $(pwd|cut -d/ -f4) == staging ]] && staging=".staging"
  echo "${BRIGHT}${RED}This will deactivate all plugins one at a time and perform curl tests for the ${NORMAL}${RED}${install} - $(pwd|cut -d/ -f4) ${BRIGHT} install.${NORMAL}"
  echo "${BRIGHT}${RED}Make sure you have permission to do this or it's on a staging install.${NORMAL}"
  read -p "Continue? "
  if [[ ${REPLY:0:1} =~ [Yy] ]] ; then
    myip="($(ip a | grep global | awk '{printf "%s|",$2}')127.0.0.1)"
    cache='_wpeprivate/active_plugins.txt'
    install=$(pwd|cut -d/ -f5)
    wp --skip-plugins --skip-themes plugin list --status=active-network --field=name > ${cache}
    ( tail --pid=$$ -n0 -F /var/log/apache2/${install}.error.log | egrep "${myip}" ) & tail_pid=$!
    for i in $(wp --skip-plugins --skip-themes plugin list --status=active-network --field=name|grep -v restricted-site-access) ; do
      wp --skip-plugins --skip-themes plugin deactivate --network ${i}
      sleep 1;
      curl -sIL "http://${install}${staging}.wpengine.com/?plugin_deactivated=${i}" | egrep '(HTTP|Location)'
    done
    wp --skip-plugins --skip-themes plugin activate --network $(cat ${cache})
    rm ${cache} ; kill $tail_pid
  else
    echo "${BRIGHT}${CYAN}Quitting and doing nothing.${NORMAL}"
  fi
}
