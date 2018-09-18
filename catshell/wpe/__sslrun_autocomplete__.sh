## Helper functions and aliases to add auto-complete functionality to
##      sudo /nas/wp/www/tools/include/ssl/run.php -f (function) -a (account) -d (domain)

# Variables
__ssl_functions="submit enable disable cancel renew get-config get-status"

#auto-complete function
function __sslrun_autocomplete__() {
  local xpat

  if [[ ${COMP_CWORD} == 1 ]]; then
    xpat=$__ssl_functions flag="-W"
  elif [[ ${COMP_WORDS[1]} =~ ^(${__ssl_functions// /|})$ ]] ; then
    if [[ ${COMP_CWORD} == 2 ]]; then
     xpat=$(ls /nas/content/live/) flag="-W"
    elif [[ ${COMP_CWORD} == 3 ]]; then
     xpat=$(grep all_domains /nas/content/live/${COMP_WORDS[2]}/wp-config.php 2>/dev/null | grep -oP "(?<==> ')[^']*" | grep -v 'wpengine.com') flag="-W"
    fi
  fi

#generate auto-complete reply.
  COMPREPLY=( $( compgen ${flag} "${xpat}" -- ${COMP_WORDS[COMP_CWORD]} ))
  if [[ -n $cluster_autocomplete_debug ]] ; then
    echo -e "\n\033[0;35mW: ${COMP_WORDS[@]} \nCW:${COMP_CWORD}\n\033[0;36mR: ${COMPREPLY[@]}\033[0m"  >> /tmp/auto-complete.debug
  fi
return 0
}

# Function to wrap the php command
function sslrun() {
   sudo php -q /nas/wp/www/tools/include/ssl/run.php -f $1 -a $2 -d $3
}
complete -F __sslrun_autocomplete__ sslrun
