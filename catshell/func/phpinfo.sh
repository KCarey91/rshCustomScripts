## View PHP info for the current working directory without having to create
##  a phpinfo file, then browse to it.   This creates the file, curls it,
##  and sends the output to less.  You can also pipe to grep.
##
## Gives the *actual* PHP configuration of the location you're at in the file system
##  since it loads up .htaccess directives when curling; as opposed to php -i which
##  just reads the global configuration and doesn't take modifications into account.
##
## phpinfo  # Will open up a less window with the output of phpinfo
## phpinfo | grep max_input_vars  # search for a specific variable in the output.
##

function phpinfo() {
  user=$(pwd|cut -d/ -f5)
  environment=$(pwd|cut -d/ -f4)
  [[ ${environment} == "staging" ]] && user="${user}.staging"
  if [[ -n ${user} && ${environment} =~ (live|staging) ]] ; then
    now=$(date +%s)
    path=${PWD//*${user}/}
    echo '<?php phpinfo(); ?>' > info.${now}.php
    phpinfo_url="${user}.wpengine.com${path}/info.${now}.php"
    status="$(curl -LIso /dev/null --write-out '%{http_code}' ${phpinfo_url})"
    case ${status} in
      200)
        curl -sL ${phpinfo_url} | lynx -dump -stdin | less ;;
      401)
        if [[ $(pwd|cut -d/ -f4) == "staging" ]]; then
          auth_info=$(php /nas/wp/www/tools/wpe.php option-get ${user%.*} nginx_basic_auth_staging | egrep '\[(user|password)\]' | awk '{printf "%s ",$3}')
        else
          auth_info=$(php /nas/wp/www/tools/wpe.php option-get ${user%.*} nginx_basic_auth | egrep '\[(user|password)\]' | awk '{printf "%s ",$3}')
        fi
        curl -sL -u${auth_info/ /:} -sL ${phpinfo_url} | lynx -dump -stdin | less ;;
       *) >&2 echo "${RED}Curl failed with status code: ${BRIGHT}${status}${NORMAL} ( ${BRIGHT}${phpinfo_url}${NORMAL} )"
    esac
    rm -f info.${now}.php
  else echo -e "${red}Must be within a user's install or staging directory.${rst}"
  fi
}
