#!/bin/bash

SOURCE=$1; shift
DEST=$1;   shift

if [ ! -d "$SOURCE" ] || [ ! -d "$DEST" ]; then
    echo "Usage: $0 SOURCE DEST ..."
    exit 1
fi

for i in "$@"; do
    #rm -rf "$DEST/$i"
    rsync -a --checksum --delete --exclude .git "$SOURCE/$i" "$DEST/$i" || exit 1
done
