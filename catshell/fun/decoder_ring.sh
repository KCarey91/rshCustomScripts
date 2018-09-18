#! /bin/bash
## perform simple text-replacement on a string for secret messages.
## Works both forward and backwards, so the same command decoodes AND encodes.
##
##      decoder_ring "text"    OR    echo "text" | decoder_ring
##      decoder_ring < file    OR    decoder_ring << EOF

decoder_ring() {
  [[ -t 0 ]] && input="$*" || input=$(cat)
  echo "${input}" | tr n-za-mN-ZA-M a-zA-Z
}
