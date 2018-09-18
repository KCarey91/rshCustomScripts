## Do you have a hard time visualizing how much is 27%? Do you wanna make cool
##  copy/pasta graphs for your friends?  (They'll think you're pretty swell)
## Use bargraph followed by a number, 1-100 (it's for percent, bro)
##        bargraph 27
## It'll give you a bargraph and even set colors so you can be like,
##  "Mmm, green is nice and good. OH NO RED IS BAD!"

function bargraph() {
  pct=$1
  if [[ $pct -lt 20 ]]
   then echo -e "${bldblu}\c"
  elif [[ $pct -lt 80 ]]
   then echo -e "${bldgrn}\c"
  elif [[ $pct -lt 100 ]]
   then echo -e "${bldylw}\c"
  else echo -e "${bldred}\c"
  fi
  v=0
  while [[ $v -le $(($pct/2)) && $v -le 50 ]]  ; do echo -e "▓\c"; v=$(($v + 1));done
  while [[ $v -le 50 ]] ; do echo -e "░\c"; v=$(($v + 1)) ; done
  echo -e "\t${pct}% ${txtrst}"
}
