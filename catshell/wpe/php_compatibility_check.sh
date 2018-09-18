#! /bin/bash
## Downloads Stallings' PHP compatibility testing plugin, installs and activates it,
##  removes zip file (~ dir) and runs a php compatibility test via wp-cli.
## Deactivates and removes the plugin when finished since it's not public yet.
##
## USAGE:   php_compatibility_check INSTALL PHP_VERSION
##    eg:   php_compatibility_check eremite 5.5
## Staging: Add -staging to the install.
##    eg:   php_compatibility_check eremite-staging 5.5

function php_compatibility_check(){
  site=$1
  version=$2
  [[ -n ${site} && -n ${version} ]] || return 1
  if [[ ${site} =~ -staging$ ]] ; then
     site=${site%%-*}
     site_path=/nas/content/staging/${site}
  else
     site_path=/nas/content/live/${site}
  fi
  if [[ -d ${site_path} ]]; then
    cd ${site_path}
    echo -e "====Testing PHP ${version} Compatibility :: ${site} ===="
    skip_plugins=$(wp plugin list --status=active --field=name | grep -v php-compatibility-checker | tr '\n' ',')
    skip_plugins="--skip-plugins=${skip_plugins%,}"

    wp plugin install php-compatibility-checker --activate ${skip_plugins} --skip-themes
    wp phpcompat ${version} ${skip_plugins} --skip-themes
    wp plugin deactivate php-compatibility-checker --uninstall ${skip_plugins} --skip-themes
  else
    echo -e "Usage:  php_compatibility_check INSTALL(-staging) VERSION"
  fi
}
