function htaccess() {
#user and version tracking
curl -IL -A $(whoami)htaccessv1.0.1 https://utilitybelt.xyz >/dev/null 2>&1

sitepath=/nas/content/live/$1

#Check that user is in an install's root directory, if not, then request sitename
if [[ ! $PWD =~ /nas/content/(live|staging)/[a-z0-9]*$ && ! $PWD =~ /nas/wp/www/(sites|staging)/[a-z0-9]*$ && ! $PWD =~ /nas/wp/www/cluster-[0-9]*/[a-z0-9]*$ ]];
then
  read -p "Please enter in the install: " sitename
  read -p "Please enter live or staging: " environment
  # Set correct environment based on user prompt
  if [[ "${environment}" =~ ^[LlPp].*$ ]]
  then
    sitepath=/nas/content/live/${sitename}
  else
    sitepath=/nas/content/staging/${sitename}
  fi
else
  sitepath=${PWD}
fi

# Check if install exists
red='\033[0;31m'
if [ ! -d "${sitepath}" ]
then 
  echo
  echo -e "${red}That install doesn't appear to be on this server. ${NC}"
  echo "CD into the site's directory and use this syntax for the command:"
  echo "htaccess <htaccess_type>"
  echo
  return
fi
# Check if the site type is defined, otherwise, prompt for it
if [[ -z "$2" ]]
then
  read -p "Is this a regular, subdomain or subdirectory install?: " sitetype
else
  sitetype="$2"
fi
# Define the gihub URL
github=https://raw.githubusercontent.com/philipjewell/htaccess/master
# Defining which htaccess file to pull based on site type
if [[ "${sitetype}" =~ ^[rR].*$ ]]
then
   htaccess="${github}/.htaccess"
elif [[ "${sitetype}" =~ ^(subdo|SUBDO).*$ ]]
then
    htaccess="${github}/.htaccess.subdomain"
elif [[ "${sitetype}" =~ ^(subdi|SUBDI).*$ ]]
then
   htaccess="${github}/.htaccess.subdir"
fi
# Set date for when moving the old htaccess file
editdate=$(date | sed -e 's/ /-/g')
cd ${sitepath}
# Move old htaccess file to the _wpeprivate directory and name it with the current date
mv .htaccess _wpeprivate/.htaccess-${editdate}
echo -e "Moved the original .htaccess to the _wpeprivate directory"
# Download new htaccess file
wget "${htaccess}" -O ".htaccess" 2>/dev/null
echo
echo -e "Created a new default .htaccess\nYou're good to go!"
echo

unset sitepath
unset environment
unset sitename
unset editdate
unset htaccess
unset sitetype
unset github
}

