#! /bin/bash
## flip text upside down
## uʍop ǝpısdn ʇxǝʇ dıןɟ

function fliptext() {
  [[ -t 0 ]] && input="$*" || input=$(cat)
  if [[ $input =~ -t ]] ; then
    text=${input/-t/}
    echo -e "${text}ノ( º _ ºノ)   \c"
    revtext=$(echo "${text}" | tr A-Za-z".?!;()_" 'ɐqɔpǝɟbɥıظʞןɯuodbɹsʇnʌʍxʎzɐqɔpǝɟbɥıظʞןɯuodbɹsʇnʌʍxʎz˙¿¡؛)(‾' | rev)
    echo "(╯°□°）╯︵ ${revtext} "
  else
    echo "$input" | tr A-Za-z".?!;()_" 'ɐqɔpǝɟbɥıظʞןɯuodbɹsʇnʌʍxʎzɐqɔpǝɟbɥıظʞןɯuodbɹsʇnʌʍxʎz˙¿¡؛)(‾' | rev
  fi
}
