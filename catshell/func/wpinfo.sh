#! /bin/bash
## Just runs a lot of wp-cli commands to print off some info about wp_options settings,
##   database information, installed plugins, themes, etc.  Super simple, but convenient.

function wpinfo() {
  alias wpc='wp --skip-plugins --skip-themes'
  echo -e "${txtgrn}     Home: ${txtrst} $(wpc option get home 2>/dev/null)"
  echo -e "${txtgrn}  SiteURL: ${txtrst} $(wpc option get siteurl 2>/dev/null)"
  echo -e "${txtgrn} Template: ${txtrst} $(wpc option get template 2>/dev/null)"
  echo -e "${txtgrn}Styleshet: ${txtrst} $(wpc option get stylesheet 2>/dev/null)"
  echo -e "${txtgrn}Permalink: ${txtrst} $(wpc option get permalink_structure 2>/dev/null)"
  echo -e "${txtgrn}  Uploads: ${txtrst} $(wpc option get upload_path 2>/dev/null)"
  db=$(grep DB_NAME wp-config.php | awk -F "\"|'" '/^\s*define/ {print $4}')
  user=$(grep DB_USER wp-config.php | awk -F "\"|'" '/^\s*define/ {print $4}')
  pass=$(grep DB_PASSWORD wp-config.php | awk -F "\"|'" '/^\s*define/ {print $4}')
  pre=$(grep table_prefix wp-config.php | awk -F "\"|'" '/^\s*\$table_prefix/ {print $1}')
  echo -e "${bldgrn}DB Info (wp-config.php):"
  echo -e "${txtgrn}DB Name:${txtrst} ${db}"
  echo -e "${txtgrn}DB User:${txtrst} ${user}"
  echo -e "${txtgrn}DB Pass:${txtrst} ${pass}"
  echo -e "${txtgrn}DB  Pre:${txtrst} ${pre}"
  mysql -u $user -p"${pass}" -e '' 2> /dev/null && result="\033[0;32mSuccess" || result="\033[0;31mFailed"
  echo -e "${bldgrn}User/Pass Test : ${result}${txtrst}"
  mysql -u $user -p"${pass}" ${db} -e '' 2> /dev/null && result="\033[0;32mSuccess" || result="\033[0;31mFailed"
  echo -e "${bldgrn}User ->DB Test : ${result}${txtrst}\n"
  wp plugin status; echo ; wp theme status;
}
