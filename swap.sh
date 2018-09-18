#!/bin/bash


swap () {
# A function made to swap out domains from multisite and single site. Made to mainly replace the multisite domains in multiple tables.
# Report any bugs of this function to alex.a.pereira@wpengine.com
#
#
# Check if a wp-config.php is present, if not, ask to check if there is one or get into a installs main root directory.
if [[ -e wp-config.php ]]
        then


# Variables to grab the database information from wp-config.php of the install.
usr=$(grep -i "db_user" wp-config.php | awk -F\' '{ print $4 }')
pw=$(grep -i "db_pass" wp-config.php | awk -F\' '{ print $4 }')
db=$(grep -i "db_name" wp-config.php | awk -F\' '{ print $4 }')
pf=$(grep -i "table_prefix" wp-config.php | awk -F\' '{ print $2 }')


    # Request for the domain that is currently located in the database and the new domain to replace it with."
    echo "Make sure to do a backup of the database by running mysqldump before making any changes to a database."
    echo "Provide the old domain you would like to change out. Ex: install.wpengine.com leave out http://"
    read old
    echo "Provide the new domain you would like to place. Ex: domain.com leave out http://"
    read new


        # Check if the multisite define is present in wp-config.php, if present proceed to switch out the domain for a multisite database.
        # If not present, replace only the home & siteurl for a single site database.
        if [[ $(grep -i "'MULTISITE'" wp-config.php | grep -o "true") == "true" ]]
        then


            # Replacing the domain in the blogs, options, site, sitemeta tables.
            mysql -u $usr -p$pw $db -e "UPDATE "$pf"options, "$pf"blogs, "$pf"site, "$pf"sitemeta SET
            "$pf"options.option_value = REPLACE(option_value, '"$old"', '"$new"'),
            "$pf"blogs.domain = REPLACE("$pf"blogs.domain, '"$old"', '"$new"'),
            "$pf"site.domain = REPLACE("$pf"site.domain, '"$old"', '"$new"'),
            "$pf"sitemeta.meta_value = REPLACE("$pf"sitemeta.meta_value, '"$old"', '"$new"')
            WHERE "$pf"options.option_name IN ('home', 'siteurl') AND
            "$pf"blogs.domain LIKE '"%$old"' AND "$pf"site.domain = '"$old"' AND "$pf"sitemeta.meta_key = 'siteurl';"


            # Replacing the domain in the sub options tables.
            for i in $(mysql -u $usr -p$pw $db -e "SELECT blog_id FROM "$pf"blogs;" | sed -e 's/^+$//g' -e 's/blog_id//' -e 's/1//');
            do mysql -u $usr -p$pw $db -e "UPDATE "$pf""$i"_options SET option_value = REPLACE(option_value, '"$old"', '"$new"')
            WHERE option_name IN ('home', 'siteurl');";
            done


            # Display how the database now looks in the blogs, options, site, sitemeta tables
            mysql -u $usr -p$pw $db -e "SELECT option_value as '"$pf"options: home & siteurl' FROM "$pf"options
            WHERE option_name IN ('home', 'siteurl');
            SELECT domain as '"$pf"blogs: domain' FROM "$pf"blogs;
            SELECT domain as '"$pf"site: domain' FROM "$pf"site;
            SELECT meta_value as '"$pf"sitemeta: siteurl' FROM "$pf"sitemeta WHERE meta_key = 'siteurl';"


            # Display how the sub options tables look for the home and siteurl
            for i in $(mysql -u $usr -p$pw $db -e "SELECT blog_id FROM "$pf"blogs;" | sed -e 's/^+$//g' -e 's/blog_id//' -e 's/1//');
            do mysql -u $usr -p$pw $db -e "SELECT option_value as '"$pf""$i"_options: home & siteurl' FROM "$pf""$i"_options
            WHERE option_name IN ('home', 'siteurl');";
            done


            # Thanks to the help of Hunter, this will swap out the define with the new domain.
            sed -i "s/.*DOMAIN_CURRENT_SITE.*/define\(\ \'DOMAIN_CURRENT_SITE\'\,\ \'$new\'\ \)\;/g" ./wp-config.php


            # Display the output of the new define
            grep -i "DOMAIN_CURRENT_SITE" wp-config.php
        else


            # If multisite define is not present in wp-config.php, only replace the home and siteurl in table options
            mysql -u $usr -p$pw $db -e "UPDATE "$pf"options SET option_value = REPLACE(option_value, '"$old"', '"$new"')
            WHERE option_name IN ('home', 'siteurl');
            SELECT option_name, option_value FROM "$pf"options WHERE option_name in ('home', 'siteurl');"
        fi
    else


        # If no wp-config.php is not found, request to be in a installs root directory or make sure there is a wp-config.php
        echo "Get into a installs root directory '/nas/content/live/install' or make sure that a wp-config.php is present."
fi
}
