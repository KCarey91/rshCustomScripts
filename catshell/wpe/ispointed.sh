#! /bin/bash

## Checks to see if a domain is pointed to WPEngine using a curl to -wpe-cdncheck-
##   Usage:  ispointed (domain)
## If no domain is specified, it tries to grab the info from the database if you're
##  in the same directory as the wp-config.php file.

function ispointed() {
if [[ -n $1 ]] ; then
  # Strip protocol and URI, then re-add http://
  domain="${1#https://}" domain="${domain#http://*}" domain="http://${domain%%/*}/"
else
  db=$(grep -i db_name wp-config.php |awk -F"'" '{print $4}'|head -n1)
  user=$(grep -i db_user wp-config.php | awk -F"'" '{print $4}'|head -n1)
  pass=$(grep -i db_pass wp-config.php |awk -F"'" '{print $4}'|head -n1)
  pre=$(grep -i table_prefix wp-config.php | awk -F"'" '{print $2}'|head -n1)
  domain=$(mysql -N -u $user -p"$pass" $db  -e "select option_value from ${pre}options where option_name='siteurl';" 2>/dev/null)
fi
echo -e "\n\033[0;35mChecking to see if \033[1;35m'${domain}'\033[0;35m is pointed. Check for a '\033[1;35m200 OK\033[0;35m' message.\033[0m"
echo -e "\033[0;36mcurl -sL -o /dev/null -w '%{http_code} - %{redirect_url}' ${domain}/-wpe-cdncheck-\033[0m\n"
  RESULT=$(curl -s -o /dev/null -w '%{http_code} - %{redirect_url}' ${domain}/-wpe-cdncheck-)
  echo -e "\033[1;31m$(echo ${RESULT} | sed 's|^200 -\(.*\)|\\033[1;32m200 OK\\033[0;32m\1\\033[0m|g')\033[0m"
  while [[ -n ${RESULT#* - } ]] ; do
    RESULT=$(curl -s -o /dev/null -w '%{http_code} - %{redirect_url}' ${RESULT#* - })
    echo -e "\033[1;31m$(echo ${RESULT} | sed 's|^200 -\(.*\)|\\033[1;32m200 OK\\033[0;32m\1\\033[0m|g')\033[0m"
  done
  echo -e "\n\033[0;35mWPE Headers (should exist if we got a 200): \033[0m"
  curl -sIL "${domain}/-wpe-cdncheck-" | grep -i X-WPE-
}
