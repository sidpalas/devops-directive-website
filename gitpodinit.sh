#!/bin/bash
set -e -o pipefail

HUGO_VERSION=0.92.2
HUGO_TAR_FILE=hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz

wget https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_TAR_FILE}
tar -xf ${HUGO_TAR_FILE}
sudo mv hugo /usr/local/bin/
rm ${HUGO_TAR_FILE}
