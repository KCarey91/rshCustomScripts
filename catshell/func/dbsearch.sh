#!/bin/bash

## Search through the database for a specific word/term.
##
## Usage:  (Run from same directory as wp-config.php to get DB info)
##    dbsearch <term> (table_name)
##
##  Multi-word searches need to be encapsulated in quotes.
##
##  Table_name is optional if you want to limit to only a specific table:
##      dbsearch "search terms" wp_posts

function dbsearch() {
  db=$(grep -i db_name wp-config.php |awk -F"'" '{print $4}'|head -n1)
  user=$(grep -i db_user wp-config.php | awk -F"'" '{print $4}'|head -n1)
  pass=$(grep -i db_pass wp-config.php |awk -F"'" '{print $4}'|head -n1)
  term="${1}"
  table="${2}"
  if [[ -n $term ]]; then
    for table in $(mysql -N -u $user -p"$pass" $db -e 'show tables;' 2>/dev/null) ; do
      if [[ ${table} =~ $2 ]]; then
        echo -e "\033[0;35mTable: \033[1;35m${table}\033[0m"
        the_query=""
        for column in $(mysql -N -u $user -p"$pass" $db -e "show columns from $table;" 2>/dev/null |awk '{print $1}') ; do
          the_query="${the_query} (${column} like \"%${term}%\") or"
        done
        mysql -u ${user} -p"${pass}" $db -e "select * from ${table} where ${the_query%or}" 2>/dev/null
      fi
    done
  else echo "Specify search terms."
  fi
}
