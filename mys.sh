## Name: mys.sh
## Desc: Automated credential MySQL wrapper
## Vers: 1.0.0
function mys
{
	if [[ -z $0 ]]
	then
		echo "Usage: mys (flags) (\"query\")"
		echo ""
		return 1
	fi
	wpconfig=$(pwd -P | awk -F"/" {'print "/nas/content/"$4"/"$5"/wp-config.php"'})
	if ! [[ -e ${wpconfig} ]]
	then
		echo -e "Install directory not found. Please make sure you're inside of an install directory before running.\n"
		return 1
	fi
	Host=$(grep DB_HOST ${wpconfig} | tail -1 | awk -F"'" {'print $4'})
	User=$(grep DB_USER ${wpconfig} | tail -1 | awk -F"'" {'print $4'})
	Pass=$(grep DB_PASSWORD ${wpconfig} | tail -1 | awk -F"'" {'print $4'})
	Name=$(grep DB_NAME ${wpconfig} | tail -1 | awk -F"'" {'print $4'})
	if [[ ${User} == "" || ${Pass} == "" || ${Name} == "" ]]
	then
		echo -e "Could not detect database credentials. Please check the wp-config.php file.\n"
		return 1
	fi
	mysql -h"${Host}" -u"${User}" -p"${Pass}" "${Name}" "$@" 2>/dev/null
	return 0
}
