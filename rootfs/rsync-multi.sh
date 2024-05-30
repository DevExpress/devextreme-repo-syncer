#!/bin/bash

OPTIND=1

ADDITIONAL_ARGS=""
KEEP_FILES=false

# Options:
# -e - additional pattern to exclude
# -k - keep extraneous files in dest folder
while getopts e:k opt; do
  case $opt in
    e)
      ADDITIONAL_ARGS+=" --exclude $OPTARG"
      ;;
    k)
      KEEP_FILES=true
      ;;
    \?)
      echo "Invalid option $OPTARG"
  esac
done

if [ "$KEEP_FILES" != true ]; then
  ADDITIONAL_ARGS+=" --delete"
fi

shift $((OPTIND-1))

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
    rsync -a --exclude .git $ADDITIONAL_ARGS "$SOURCE/$i" "$DEST/$i" || exit 1
done
