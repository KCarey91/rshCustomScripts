
#!/bin/bash
postprocesscheck () 
{
    local SP='-------------------------------';
    if [[ -z $1 ]]; then
        local INSTALL=$(pwd | cut -d'/' -f5);
    else
        local INSTALL=$1;
    fi;
        if [[ -f /nas/content/live/$INSTALL/wp-config.php ]]; then
            wpe $INSTALL > /dev/null;
            IFS=" " read -r DATABASE PASSWORD USER <<< $(grep "^define.*DB_[NUP]" wp-config.php | sort | cut -d"'" -f4);
            local PREFIX=$(grep -i table_prefix wp-config.php |awk -F"'" '{print $2}');
            if [[ -n $(grep -E "^define(.*)MULTISITE(.*)true" wp-config.php) ]]; then
                IFS=" " read -r OTABLE TABLE ROW <<< $(echo "sitemeta meta_value meta_key");
            else
                IFS=" " read -r OTABLE TABLE ROW <<< $(echo "options option_value option_name");
            fi;
            local CEREAL=$(mysql -u $USER -p$PASSWORD -e "use $DATABASE; SELECT ${TABLE} FROM ${PREFIX}${OTABLE} WHERE ${ROW} LIKE '%post_process%'" 2>/dev/null | tail -n+2);
            local PPRULES=$(echo -e "\n\n$CEREAL" | sed -r 's/\#\"\;s\:([0-9]*)\:\"/\#\ \=\>\ /g' | sed -r 's/(s*)\"\;s\:([0-9]*)\:\"/\n/g' | sed -r 's/a\:([0-9]*)\:\{s\:([0-9]*)\:\"//g' | sed -r 's/\"\;\}$//g' | grep -v '^$';);
            if [[ ! $2 = --clean ]]; then
                echo -e "\n\n ${red}${SP}${SP}\n${yellow} I found the following rule(s) in place for the ${red}$INSTALL${yellow} install.\n ${red}${SP}${SP}${NC}\n\n$PPRULES\n\n";
            else
                echo "$PPRULES";
            fi;
        else
            echo -e "\n\n${SP}\n   ${red}Invalid install provided\n${SP}\n\n ${blue}Usage${NC}: postprocesscheck [install]\n\n";
        fi;
}
postprocessgen () 
{
    echo -en "\n What is the ${red}INSTALL${NC} this rule will be used for? ";
    read INSTALLRULE;
    echo -en " What is the ${red}DOMAIN${NC} this rule will be used for? ";
    read DOMAIN;
    DOMAINB=$(echo $DOMAIN | sed 's/www\.//g');
    echo -en " What is the ${red}CDN ZONE${NC} for the ${blue}$INSTALLRULE${NC} install ${yellow}(optional)${NC}: ";
    read ZONE;
    echo -en " What is the ${red}CUSTOM CDN URL${NC}, if one applies? ";
    read CDN;

    echo -e "\nWhich post-processing rule would you like?\n\n1.) ${green}DOMAIN SSL${NC} - https://${DOMAIN}/wp-(content|includes) \n2.) ${green}DEFAULT CDN SSL${NC} - https://${ZONE}-wpengine.netdna-ssl.com/wp-(content|includes) \n3.) ${green}CUSTOM CDN SSL${NC} - https://${CDN}/wp-(content|includes) \n4.) ${red}CUSTOM CDN NON-SSL ${NC}- http://${CDN}/wp-(content|includes)\n5.) ${red}DEFAULT CDN NON-SSL ${NC}- http://$ZONE.wpengine.netdna-cdn.com/wp-(content|includes) \n6.) ${red}DOMAIN NON-SSL${NC} - http://${DOMAIN}/wp-(content|includes) \n\n";
    read DISTR;
    echo;
    case $DISTR in
        1)
            echo -e "${yellow}Redirect all objects through ${green}https://${yellow} via ${red}the domain${yellow}:${NC}\n\n#https?://(www\.)?($DOMAINB|$INSTALLRULE.wpengine.com)/wp-(content|includes)# => https://$DOMAIN/wp-"'$3'
        ;;
        2)
            echo -e "${yellow}Redirect all objects through ${green}https://${yellow} via the ${red}CDN domain${yellow}:${NC}\n\n#https?://(www\.)?($DOMAINB|$INSTALLRULE.wpengine.com|$ZONE.wpengine.netdna-(ssl|cdn).com)/wp-(content|includes)# => https://$ZONE-wpengine.netdna-ssl.com/wp-"'$4'
        ;;
        3)
            echo -e "${yellow}Redirect all objects through ${green}https://${yellow} via the ${red}CUSTOM CDN URL${yellow}:${NC}\n\n#https?://(www\.)?($DOMAINB|$INSTALLRULE.wpengine.com|$ZONE.wpengine.netdna-(ssl|cdn).com)/wp-(content|includes)# => https://$CDN/wp-"'$4'
        ;;
        4)
            echo -e "${NC}Redirect all objects through ${red}http://${NC} via the ${yellow}custom CDN URL${NC}:\n\n#https?://(www\.)?($DOMAINB|$INSTALLRULE.wpengine.com|$ZONE.wpengine.netdna-(ssl|cdn).com)/wp-(content|includes)# => http://$CDN/wp-"'$4'
        ;;
        5)
            echo -e "${NC}Redirect all objects through ${red}http://${NC} via the ${yellow}CDN domain:${NC}\n\n#https?://(www\.)?($DOMAINB|$INSTALLRULE.wpengine.com|$ZONE-wpengine.netdna-(ssl|cdn).com)/wp-(content|includes)# => http://$ZONE.wpengine.netdna-cdn.com/wp-"'$4'
        ;;
        6)
            echo -e "${NC}Redirect all objects through ${red}http://${NC} via ${yellow}the domain${NC}:\n\n#https?://(www\.)?($DOMAINB|$INSTALLRULE.wpengine.com)/wp-(content|includes)# => http://$DOMAIN/wp-"'$3'
        ;;
    esac;
    echo
}
postprocessclear () 
{
    local SP='-------------------------------';
    if [[ -z $1 ]]; then
        local INSTALL=$(pwd | cut -d'/' -f5);
    else
        local INSTALL=$1;
    fi;
    if [[ -f /nas/content/live/$INSTALL/wp-config.php ]]; then
        IFS=" " read -r DATABASE PASSWORD USER <<< $(grep "^define.*DB_[NUP]" wp-config.php | sort | tr '"' "'" | cut -d"'" -f4);
        local PREFIX=$(grep -i table_prefix wp-config.php |awk -F"'" '{print $2}');
        if [[ -n $(grep -E "^define(.*)MULTISITE(.*)true" wp-config.php) ]]; then
            IFS=" " read -r TABLE COLUMN ROW <<< $(echo "sitemeta meta_key meta_value");
        else
            IFS=" " read -r TABLE COLUMN ROW <<< $(echo "options option_name option_value");
        fi;
        local REMOVED=$(postprocesscheck $INSTALL --clean);
        mysql -u $USER -p$PASSWORD $DATABASE -e "update ${PREFIX}${TABLE} set ${ROW} = 'a:0:{}' where ${PREFIX}${TABLE}.${COLUMN} = 'regex_html_post_process'" &> /dev/null && echo -e "\n\n ${blue}${SP}${SP}\n${green}    These rules have been ${red}REMOVED${green} for the ${yellow}$INSTALL${green} install.\n ${blue}${SP}${SP}${NC}\n\n${REMOVED}\n\n";
    else
        echo -e "\n\n${SP}\n  No ${red}install${NC} found/name provided was invalid.\n${SP}\n\n ${blue}Usage${NC}: postprocessclear [install]\n\n";
    fi
}

postprocess () 
{
        echo -e "\n ${blue}postprocess${NC} should be ran from an install directory to locate rules$\n\n1) ${green}CHECK${NC} for post-processing rules\n2) ${yellow}GENERATE${NC} a post-processing rule\n3) ${red}REMOVE${NC} all post-processing rules\n\n";

read ROUTE;
    case $ROUTE in
        1)
            postprocesscheck
        ;;
        2)
            postprocessgen
        ;;
        3)
            postprocessclear
        ;;
    esac
}
