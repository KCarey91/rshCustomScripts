figcon(){
sitepath=/nas/wp/www/sites/$1
dbName=$(grep 'DB_NAME' wp-config.php | awk {'print $3'} | tr -d \' )
dbEcho= echo $dbName
Install=`echo $PWD|cut -d"/" -f5`;


# Explain command syntax if blank
if [[ -z $1 ]]
then
  echo "I need the install name!  Like this:"
  echo "figcon <install_name>"
  
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

#read -p "How many revisions do they need? " figcon
# Run the commands to fill in all the information
echo -e "Sounds good. Generating a new config for..."

for site in "$@"
do
	echo -e "$site"
    echo -e "$dbEcho"
    echo -e "$Install"
	
done

echo -e "\nAlright, all the sites have been updated with the revision settings.\nPlease check OverDrive to verify the changes."
}
