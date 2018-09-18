#! /bin/bash

## Got a bunch of IPs slammin' a box and want to see where all these jerks are coming from?
## iplocate uses and API Key from http://ipinfodb.com to geolocate those bad boys.
## ip2cc? geoiplookup? Those commands are piles of junk and only give you the Country Code.
## This one gives you all kinds of useful crap, like city, state, country, zip, lat/longitude, time offset.
## Just use iplocate {whole bunch of IPs} to pump out a ton of output for you to parse through or copypasta.

function iplocate() { echo
 for ip in $*; do
   curl -s "http://api.ipinfodb.com/v3/ip-city/?key=27c96b2f174847558c945cc3d8e315fd68c53a51fec691c8bbecb75978a5ab09&ip=$1&format=raw" |
     awk -F';' '{print "\033[1;32mIP Address:\033[0;32m\t",$3,"\n\033[1;32mCountryCode:\033[0;32m\t",$4,"\n\033[1;32mCountryName:\033[0;32m\t",$5,"\n\033[1;32mRegionName:\033[0;32m\t",$6,"\n\033[1;32mCityName:\033[0;32m\t",$7,"\n\033[1;32mZipCode:\033[0;32m\t",$8,"\n\033[1;32mMap:\033[0;32m https://www.google.com/maps/place/"  $9  ","  $10 "\033[0m"'}
 done
}
