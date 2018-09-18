#!/bin/bash

## This enables mod_geoip for a customer and greps out the geoip options to confirm success
## At the end, it also prints out a neat copy/pasta ticket response to explain that and provides
##   links to support/GEOIP plugin download page.
##
## Usage:   geoip-enable (install-name) [flags]   -- Pulls from current directory if no user specified.
##   install-name has to be supplied in the first position if flags are provided.
##   Flags:  --country --region --city --zip --latitude --longitude
##    (If no flags provided, just does country_code and region/state)

function geoip-enable {
  [[ -z $1 ]] && user=$(pwd|cut -d/ -f5) || user=$1
  if [[ -n $user && -f /nas/wp/www/sites/${user}/wp-config.php ]]; then
    [[ $* =~ --country ]] && gip_buckets='$geoip_country_code:'
    [[ $* =~ --(region|state) ]] && gip_buckets="${gip_buckets}\$geoip_region:"
    [[ $* =~ --city ]] && gip_buckets="${gip_buckets}\$geoip_city:"
    [[ $* =~ --(zip|postal) ]] && gip_buckets="${gip_buckets}\$geoip_postal_code:"
    [[ $* =~ --latitude ]] && gip_buckets="${gip_buckets}\$geoip_latitude:"
    [[ $* =~ --longitude ]] && gip_buckets="${gip_buckets}\$geoip_longitude:"
    [[ -z ${gip_buckets} ]] && gip_buckets='$geoip_country_code:$geoip_region:'
    echo -e "\033[1;36mEnabling for the following buckets: \033[0;36m ${gip_buckets}\033[0m"
    read -p "Continue? [y/N]" gip_confirm
    if [[ ${gip_confirm:0:1} =~ ^[yY]$ ]]; then
      echo -e "\033[1;32mEnabling GEOIP for \033[0;32m${user}\033[1;32m : \033[0m"
      php /nas/wp/www/tools/wpe.php option-set $user geoip-rules '[{"url":"^/*","entities":"'${gip_buckets}'"}]'
      php /nas/wp/www/tools/wpe.php option-set $user geoip 1
      php /nas/wp/www/tools/wpe.php options $user | grep geoip; echo -e "\n\n"
      echo -e "\033[1;32m - Running APPLY\033[0m"
      sudo /nas/wp/ec2/cluster apply ${user} &>/dev/null
      echo -e "\033[1;32m - Running REGEN\033[0m"
      sudo /nas/wp/ec2/cluster regen ${user} &>/dev/null
    fi
  else echo -e "\033[1;31mUser '\033[0;31m$user\033[1;31m' not found/home dir doesn't exist.\033[0m"
  fi
  unset gip_buckets gip_confirm
}
