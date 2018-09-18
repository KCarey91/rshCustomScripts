## ties into the 'clb' function 'wpephp' and 'get_for_thing' from the thing.sh file
## to print out DNS info
##
##  Example:
##             This is a Google POD, this does not have a CLB:
##
##             POD IP:	104.154.148.226
##
##              Domain Name: jediknight.wpengine.com
##                Domain IP: 104.154.148.226
##                   Who IP: Google Cloud
##             X-WPE-Cluster: 120001
##             X-WPE-Install: jediknight
##
##              Domain Name: jeffistotallyawesome.space
##                Domain IP: 104.27.184.111
##                   Who IP: CloudFlare
##                Domain IP: 104.27.185.111
##                   Who IP: CloudFlare
##             X-WPE-Cluster: 120001
##             X-WPE-Install: jediknight
function check-site() {
  installcheck
  if [[ $? -eq 255 ]]; then
    echo -e "\n**************************************************"
    echo -e " Uh ohs. Looks like You're not in a valid install"
    echo -e "   directory or the last-mod file is missing."
    echo -e "**************************************************\n"
  else
    INSTALLREGEX='^[a-zA-Z]{1}[a-zA-Z0-9]{2,13}$'
    checksitepath
    if [[ $sitepath =~ $INSTALLREGEX ]] ; then

      host=`hostname` && pod=`cut -d- -f2 <<<"${host}"`

      clb $pod

      domain=$(wpephp option-get ${sitepath} domains | grep -oE "[A-Za-z0-9.-]+\.[A-Za-z]{2,}")

      get_for_thing "${domain}"

    elif [ -z $sitepath ] ; then
      echo -e "\n${yellow}What is the install name:${NC}"
      read -e site_path
      if [[ $site_path =~ $INSTALLREGEX ]] ; then
        host=`hostname` && pod=`cut -d- -f2 <<<"${host}"`

        clb $pod

        domain=$(wpephp option-get ${sitepath} domains | grep -oE "[A-Za-z0-9.-]+\.[A-Za-z]{2,}")

        get_for_thing "${domain}"
      else
        echo -e "${red}Need valid Install Name!${NC}\n"
      fi
    else
      echo -e "${red}Need valid Install Name!${NC}\n"
    fi
  fi
}

## Ever wonder "Hey does this server have a CLB?" or
## "Hey what is the actual IP of this server?"
## well look no further!! this function will show you what type of server
## what datacenter and what the IP is of the server and if applicable the CLB

function clb () { # CLB There	 			<pod_number>
  REGEX="[0-9]{2,6}"
  BIRTHINGPOD="50.116.58.222"
  RAXOLD="^[1-9]{1}[0-9]{2}$|^999$"
  RAX53="^[1]{1}[0-9]{4}$|^19999$"
  LINODE53="^[2]{1}[0-9]{4}$|^29999$"
  RAXNORM="^[3]{1}[0-9]{4}$|^39999$"
  LINODENORM="^[4]{1}[0-9]{4}$|^49999$"
  RAXHA="^[5]{1}[0-9]{4}$|^59999$"
  RAXCLUSTER="^[6-7]{1}[0-9]{4}$|^[6-7]9999$"
  RAXHA2="^[8]{1}[0]{1}[09]{3}$|^80999$"
  LINODEHA="^[8]{1}[1-4,6-9]{1}[0-9]{3}$|^89999$"
  AMAZON="^[9]{1}[0-9]{4}$|^99999$"
  GOOGLE="^[1]{1}[0-9]{5}$|^139999$"
  CHECKHOST=$(hostname | cut -d- -f2)
  # pod provided, or not
  if [[ $1 =~ $REGEX ]] ; then
    CID=$1
    if [[ $CID =~ $RAXOLD ]] || [[ $CID =~ $RAX53 ]] || [[ $CID =~ $RAXNORM ]] ; then
      echo -e "\nThis is a RAX pod checking for CLB:\n"

      CLB_IP=$(dig lbmaster-$CID.wpengine.com +short A)
      echo -e "${purple}CLB IP:${NC}\t$CLB_IP"

      POD_IP=$(dig pod-$CID.wpengine.com +short A)
      echo -e "${teal}POD IP:${NC}\t$POD_IP";

      if [[ "$CLB_IP" == "$BIRTHINGPOD" ]] ; then
        echo -e "\n${yellow}The $CLB_IP is pointing to the Birthing Pod\n
        ${green}pod-$CID is un-clb-ified.${NC}\n"

      elif [[ "$CLB_IP" == "$POD_IP" ]] ; then
        echo -e "\n${green}Congrats. $CID is un-clb-ified.${NC}\n";
      else
        echo -e "\n${yellow}pod-$CID is clb'd${NC}\n";
      fi
    elif [[ $CID =~ $RAXHA ]] || [[ $CID =~ $RAXHA2 ]] ; then
      echo -e "\nThis is a RAX HA pod checking for CLB:\n"

      CLB_IP=$(dig lbmaster-$CID.wpengine.com +short A)
      for IP in $CLB_IP;
      do
        echo -e "${purple}CLB IP:${NC}\t$IP"
      done

      POD_IP=$(dig pod-$CID.wpengine.com +short A)

      if [[ "$POD_IP" == "$BIRTHINGPOD" ]] ; then
        POD_IP=$(ifconfig | grep "inet\ " | awk '{print $2}' | sed 's/addr\://g' | grep -v "127.0.0.1")
        echo -e "${teal}POD IP:${NC}\t$POD_IP\n"
      else
        echo -e "${teal}POD IP:${NC}\t$POD_IP\n"
      fi
    elif [[ $CID =~ $LINODE53 ]] || [[ $CID =~ $LINODENORM ]] ; then
      echo -e "\nThis is a Linode POD, this does not have a CLB:\n"
      POD_IP=$(dig pod-$CID.wpengine.com +short A)
      echo -e "${teal}POD IP:${NC}\t$POD_IP\n"
    elif [[ $CID =~ $RAXCLUSTER ]] ; then
      echo -e "\nThis is a RAX Cluster checking for CLB:\n"

      CLB_IP=$(dig lbmaster-$CID.wpengine.com +short A)
      for IP in $CLB_IP;
      do
        echo -e "${purple}CLB IP:${NC}\t$IP"
      done

      POD_IP=$(dig pod-$CID.wpengine.com +short A)

      if [[ "$POD_IP" == "$BIRTHINGPOD" ]] ; then
        POD_IP=$(ifconfig | grep "inet\ " | awk '{print $2}' | sed 's/addr\://g' | grep -v "127.0.0.1")
        echo -e "${teal}POD IP:${NC}\t$POD_IP\n"
      else
        echo -e "${teal}POD IP:${NC}\t$POD_IP\n"
      fi
    elif [[ $CID =~ $LINODEHA ]] ; then
      echo -e "\nThis is a Linode HA pod checking for CLB:\n"

      CLB_IP=$(dig lbmaster-$CID.wpengine.com +short A)
      for IP in $CLB_IP;
      do
        echo -e "${purple}CLB IP:${NC}\t$IP"
      done

      POD_IP=$(dig pod-$CID.wpengine.com +short A)

      if [[ "$POD_IP" == "$BIRTHINGPOD" ]] ; then
        POD_IP=$(ifconfig | grep "inet\ " | awk '{print $2}' | sed 's/addr\://g' | grep -v "127.0.0.1")
        echo -e "${teal}POD IP:${NC}\t$POD_IP\n"
      else
        echo -e "${teal}POD IP:${NC}\t$POD_IP\n"
      fi
    elif [[ $CID =~ $AMAZON ]] ; then
      echo -e "\nThis is an Amazon pod checking for CLB:\n"

      CLB_IP=$(dig lbmaster-$CID.wpengine.com +short | grep -v "cluster.*")
      for IP in $CLB_IP;
      do
        echo -e "${purple}CLB IP:${NC}\t$IP"
      done

      if [[ "$POD_IP" == "$BIRTHINGPOD" ]] && [[ "$CID" == "$CHECKHOST" ]] ; then
        POD_IP=$(ifconfig | grep "inet\ " | awk '{print $2}' | sed 's/addr\://g' | grep -v "127.0.0.1")
        echo -e "${teal}POD IP:${NC}\t$POD_IP\n"
      else
        CID_pod=$(hostname)
        POD_IP=$(dig $CID_pod.wpengine.com +short A)
        echo -e "\nCurrent POD:"
        echo -e "${teal}POD IP:${NC}\t$POD_IP\n"
      fi
    elif [[ $CID =~ $GOOGLE ]] ; then
      echo -e "\nThis is a Google POD, this does not have a CLB:\n"
      POD_IP=$(dig pod-$CID.wpengine.com +short A)
      if [[ "$POD_IP" == "$BIRTHINGPOD" ]] ; then
        echo -e "\n${yellow}The $POD_IP is pointing to the Birthing Pod! The pod CNAME needs to be fixed!${NC}"
        echo -e "\n${yellow}Try running: ${green}kitt dns:ensure pod-$CID A <CorrectIP>${NC}"
      else
        echo -e "${teal}POD IP:${NC}\t$POD_IP\n"
      fi
    fi

  else
    echo -e "\n${red}I need a pod number yo!${NC}\n"
  fi
}

function get_for_thing(){

  echo -e "${1}" |
  while read domain_name ; do
    echo -e "\n ${blue}Domain Name:${NC} ${domain_name}"
    getip ${domain_name}
    curl_check_site=$(curl --connect-timeout 1 -sIL ${domain_name}/-wpe-cdncheck- | grep -iE "X-WPE-(Cluster|Install|Forwarded)" | sort -rn | uniq -c | awk '{print $2,$3}')
    echo -e "${curl_check_site}"
  done
  echo -e ""
}
