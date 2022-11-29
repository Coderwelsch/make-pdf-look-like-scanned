#!/bin/bash

set -e
export PATH=/usr/local/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH

for file in "$@"; do
  base=${file%.pdf}
  base=$base"_scanned.pdf"

  # Split PDF into pages
  echo "Splitting $base into separate pages"
  pdfseparate "$file" /tmp/fake-scan-split-%04d.pdf

  # Loop over the pages
  for splitFile in /tmp/fake-scan-split-*.pdf; do
    splitFileBase=${splitFile%.pdf}
    splitFileScanned=$splitFileBase"_scanned.pdf"

    # Slightly rotate page, add a bit of noise and output a flat pdf
    convert -density 130 -trim -flatten "$splitFile" -attenuate 0.2 +noise Gaussian -rotate "$([ $((RANDOM % 2)) -eq 1 ] && echo -)0.$(($RANDOM % 8 + 1))" \( +clone -background black -shadow 30x5+5+5 \) +swap -background white -layers merge +repage "$splitFileScanned"
    echo "Output page $splitFileBase to $splitFileScanned"
  done

  # Combine the PDFs, add noise across the entire document, apply sharpening, convert to b&w, soften the blacks slightly
  convert -density 130 $(ls -rt /tmp/fake-scan-split-*_scanned.pdf) -attenuate 0.2 +noise Multiplicative -sharpen 0x1.0 -colorspace Gray +level 15%,100% "$base"
  echo "PDF re-combined to $base"

  # Remove all the temporary PDFs
  echo "Cleaning up"
  rm /tmp/fake-scan-split-*.pdf
done
