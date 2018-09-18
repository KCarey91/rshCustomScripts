#!/bin/bash
## Print off post-processing rules from db for the site. (or primary site in multisite)
##   Will eventually support multisites as well.

function post_processing_rules() {
  db=$(grep DB_NAME wp-config.php | awk -F "\"|'" '/^\s*define/ {print $4}')
  user=$(grep DB_USER wp-config.php | awk -F "\"|'" '/^\s*define/ {print $4}')
  pass=$(grep DB_PASSWORD wp-config.php | awk -F "\"|'" '/^\s*define/ {print $4}')
  pre=$(grep table_prefix wp-config.php | awk -F "\"|'" '/^\s*\$table_prefix/ {print $2}')
  pprule=$(mysql -u $user -p"$pass" $db -Ne "select option_value from ${pre}options where option_name='regex_html_post_process';" 2>/dev/null)
  echo "<?php print_r(unserialize('$pprule')); ?>" | php | sed -e 1,2d -e \$d -e 's|\[\?#\]\?|#|g'
}
