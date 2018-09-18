cronFun(){
sitepath=/nas/wp/www/sites/$1

# Explain command syntax if blank
if [[ -z $1 ]]
then
  echo "I need the install name!  Like this:"
  echo "Alternate Cron on for <install_name> <install_name> <install_name>"
  return
fi

# Checking if install exists
for a in "$@"
do
if [[ ! -d "/nas/wp/www/sites/$a" ]]
then
	echo -e "$a doesn't appear to be on this server."
	return
fi
done

# Get revision number

read -p "Type True to turn Alternate Cron on or NULL for off " cronFun


# Run the commands to fill in all the information
echo -e "Sounds good. Changing cron settings for..."

for site in "$@"
do
	echo -e "$site"
	php /nas/wp/www/tools/wpe.php option-set $site manual_cron  "$cronFun" && cluster regen $site
done


echo -e "\nAlright, all the sites have been updated with the cron settings.\nPlease check OverDrive to verify the changes."
}
