function 50xplugin() {
#user and version tracking
curl -IL -A $(whoami)50xpluginv1.0.1 https://utilitybelt.xyz >/dev/null 2>&1

red='\033[0;31m'
# Check if the environment for the install you're restoring to is in the argument, otherwise, prompt for install name
if [[ -z "${1}" ]]
then
  read -p "Type the sitename: " site
else
  site="${1}"
fi

#add optional path to curl instead of only curling the home page
[[ -n ${2} ]] && filepath=${2} || filepath=""

#define the sitepath
sitepath=/nas/wp/www/sites/${site}
#find pod number
pod=$(php /nas/wp/www/tools/wpe.php option-get ${site} cluster)

#if pod number is null
if [[ -z ${pod} ]]
then
	pod="${red}NO POD FOUND ${NC}"
fi

# Check to see if the site exists on this server
if [[ ! -d "${sitepath}" ]]
then 
  echo
  echo -e "${red}That install doesn't appear to be on this server. ${NC}"
  echo -e "Looks like that install is on pod: ${pod}"
  echo "Here's the syntax of this command:"
  echo "50xplugin <install_name>"
  echo
  return
fi

#if site is multisite, don't use
if [[ -n $(grep "define( 'MULTISITE', true );" ${sitepath}/wp-config.php) ]]
then
  echo -e "\n${red}Looks like this install is a multisite, \ntherefore this script will not provide accurate results...${NC}\n"
  return
fi

# Find table prefix
tableprefix=$(grep "table_prefix" ${sitepath}/wp-config.php | cut -c 18- | head -c -4)
#find the password for the database using wpephp
password=$(php /nas/wp/www/tools/wpe.php option-get ${site} db_password)
#define the domain to curl by pulling it from the database
dbsiteurl=$(mysql -u${site} -p${password} wp_${site} -e "select option_value from ${tableprefix}_options where option_name = 'siteurl';")

#remove the option_value from the database siteurl in order to set the siteurl
siteurl=$(echo ${dbsiteurl} | sed -e "s/option_value\s//g")

cd /nas/wp/www/sites/${site}/wp-content/plugins
echo -e "${red}Please wait for script to finish. DO NOT STOP IT! ${NC}"
sleep 3
echo -e "\nDisabling plugins...\nThen cURLing: ${siteurl}/${filepath}"

#disabling all plugins
for x in *
do mv "${x}" "${x}".bak
done

#if site is using basic auth, use wpephp to login creds
if [[ -n $(php /nas/wp/www/tools/wpe.php option-get ${site} nginx_basic_auth) ]]
then 
  basicauthu=$(php /nas/wp/www/tools/wpe.php option-get ${site} nginx_basic_auth | grep "user" | cut -c 15-)
  basicauthpass=$(php /nas/wp/www/tools/wpe.php option-get ${site} nginx_basic_auth | grep "password" | cut -c 19-)
  login="--user ${basicauthu}:${basicauthpass} "
else
  login=""
fi

#reenable plugins one by one, then curl the site 
for plugin in *
do echo -e "\n"${plugin/.bak}" was enabled and the site returns:"
mv "$plugin" "${plugin/.bak}"
curl ${login}-sIL --cookie "wordpress_logged_in=test" "${siteurl}/${filepath}?${plugin}" 2>/dev/null | grep "HTTP/1.1" | cut -c10-34
mv "${plugin/.bak}" "${plugin}"
done

echo -e "\nRe-enabling plugins...\n";
for plugin in *
do mv "${plugin}" "${plugin/.bak}"
done

unset siteurl
unset filepath
unset plugin
unset x
unset site
unset password
unset dbsiteurl
unset sitepath
}


