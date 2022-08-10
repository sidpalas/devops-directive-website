#!/bin/bash
set -e -o pipefail

HUGO_VERSION=0.76.5
HUGO_TAR_FILE=hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz

wget https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_TAR_FILE}
tar -xf ${HUGO_TAR_FILE}
mv hugo /workspace
rm ${HUGO_TAR_FILE}

printf 'export PATH="%s:$PATH"\n' "/workspace" >> $HOME/.bashrc
export PATH="/workspace:$PATH"
