function apacheload() {
#user and version tracking
curl -IL -A $(whoami)apacheloadv1.1.1 https://utilitybelt.xyz >/dev/null 2>&1
#find moments of highest load:
highload=$(LANG=C sar -q | egrep -v "CPU|ldavg-1" | awk '{print $4,$1}' | sort -rn | head -5)
year=$(date +"%Y")
echo -e "Highest times of load: "
echo "${highload}"
#grab only the highest moment of load
highest=$(echo "${highload}" | head -1 | awk '{print $2}')
#strip the last few characters from the highest load so it gets the number of hits for a 10 minutes time frame
loadtime=$(echo "${highest::-4}")
echo
#find all the sites on the server
installsonpod=$(ls -A /nas/content/live)
#find sites with most apache hits from the above time:
echo -e "Sites with most apache hits from ${loadtime}0 - ${loadtime}9: "
for site in ${installsonpod}; do echo -n "${site} - "; cat /var/log/apache2/${site}.access.log /var/log/apache2/${site}.access.log.1 | grep "${year}:${loadtime}" | wc -l; done | awk '{print $3,$2,$1}' | sort -rn | head
#hardest hitter
hardesthitter=$(for site in ${installsonpod}; do echo -n "${site} - "; cat /var/log/apache2/${site}.access.log /var/log/apache2/${site}.access.log.1 | grep "${year}:${loadtime}" | wc -l; done | awk '{print $3,$2,$1}' | sort -rn | head -1 | awk '{print $3}')
#for the top site, find what is getting hit the hardest
echo -e "\n${hardesthitter}'s apache offender results from ${loadtime}0 - ${loadtime}9 (with stripped queries): "
for apacheoff in ${hardesthitter}; do cat /var/log/apache2/${apacheoff}.access.log /var/log/apache2/${apacheoff}.access.log.1 2>/dev/null | grep "${year}:${loadtime}" | awk '{print $7}' | sed -e 's/\?.*//g' | sort | uniq -c | sort -rn | head -5; done
#IP offender for that time frame
echo -e "\n${hardesthitter}'s IP offender results from ${loadtime}0 - ${loadtime}9: "
for ipoff in ${hardesthitter}; do cat /var/log/apache2/${ipoff}.access.log /var/log/apache2/${ipoff}.access.log.1 | grep "${year}:${loadtime}" | awk '{print $1}' | sort | uniq -c | sort -rn | head -5; done
#User Agent offender for that time frame
echo -e "\n${hardesthitter}'s User Agent offender results from ${loadtime}0 - ${loadtime}9: "
for uaoff in ${hardesthitter}; do cat /var/log/apache2/${uaoff}.access.log /var/log/apache2/${uaoff}.access.log.1 | grep "${year}:${loadtime}" | cut -d'"' -f6 | sort | uniq -c | sort -rn | head -5; done
unset highload
unset highest
unset loadtime
unset site
unset hardesthitter
unset apacheoff
unset year
unset ipoff
unset uaoff
}
#/var/log/recap/resources_20160418-175001.log
