#! /bin/bash

## Prints off information regarding a database's size and number of rows by
##  table for diagnosing slowness on a site from MySQL queries.
## Run from same directory as wp-config.php
##
## Legend:  Green table names = WP Core tables ;; Yellow = Non-core tables
##

function dbstat() {
  db=$(grep -i db_name wp-config.php |awk -F"'" '{print $4}'|head -n1)
  user=$(grep -i db_user wp-config.php | awk -F"'" '{print $4}'|head -n1)
  pass=$(grep -i db_pass wp-config.php |awk -F"'" '{print $4}'|head -n1)
  mysql -u$user -p"$pass" information_schema -N -e "select table_schema,table_name,data_length,table_rows from TABLES where table_schema='$db'" 2>/dev/null |
    sort -k4nr |
    awk 'BEGIN {printf "\033[1;35m%-25s%-60s%20s%20s\033[0m\n", "table_schema","table_name (\033[1;32mDefault\033[1;35m|\033[1;33mAdded\033[1;35m)","data_length","table_rows"} ;
      {if ($3 >= 1048576) size=$3/1024/1024" MB"; else if ($3 > 1024) size=$3/1024" KB"; else size=$3
      if (match("wp_options wp_usermeta wp_postmeta wp_posts wp_term wp_terms wp_term wp_users wp_commentmeta wp_comments wp_links wp_term_relationships wp_term_taxonomy", $2)) table="\033[1;32m" $2 "\033[0m" ; else table="\033[1;33m" $2 "\033[0m"
      printf "%-25s%-60s%-20s%-20s\n", $1,table,size,$4}'
}
