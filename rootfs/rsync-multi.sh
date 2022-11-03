#!/bin/bash

SOURCE=$1; shift
DEST=$1;   shift

if [ ! -d "$SOURCE" ] || [ -z "$DEST" ]; then
    echo "Usage: $0 SOURCE DEST ..."
    exit 1
fi

mkdir -p "$DEST"

echo "rsync $SOURCE to $DEST"

for i in "$@"; do
    [ "$i" == "/" ] || echo "  $i"
    rsync -a --delete --exclude .git "$SOURCE/$i" "$DEST/$i" || exit 1
done
