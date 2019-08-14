#!/usr/bin/env bash

if [ "$2" = "" ]; then
    echo "usage: $(basename $0) <backup-file> <target-dir>"
    exit 1
fi

if [[ "$(basename $1)" =~ ^((.+)_[^_]+_(base|diff))(\.1\.dar)?$ ]]; then
    SOURCE_PATH=$(dirname $1)
    SOURCE_FILE=${BASH_REMATCH[1]}
    SOURCE_NAME=${BASH_REMATCH[2]}
    
    if [ ! -f "$SOURCE_FILE.1.dar" ]; then
        echo "backup-file not found"
        exit 1
    fi
    
    NUM=$(ls -1 "$SOURCE_PATH/$SOURCE_NAME"_*_base.1.dar 2>/dev/null | wc -l)

    if [ $NUM -eq 0 ]; then
        echo "base file not found for $1"
        exit 1
    elif [ $NUM -ne 1 ]; then
        echo "ambigous base file for $1"
    fi
else
    echo "unable to parse backup-filename"
    exit 1
fi

if [ ! -d "$2" ]; then
    echo "target directory does not exist"
    exit 1
fi

TARGET=$2/$SOURCE_NAME

if [ -e "$TARGET" ]; then
    echo "target path already exists $TARGET"
    exit 1
fi

mkdir "$TARGET"

for i in $(ls -1 "$SOURCE_PATH/$SOURCE_NAME"_*_base.1.dar 2>/dev/null) $(ls -1 "$SOURCE_PATH/$SOURCE_NAME"_*_diff.1.dar 2>/dev/null); do
    echo "Exctracting $i"
    
    dar -x "$(dirname $i)/$(basename $i .1.dar)" -O -w -R "$TARGET"
    
    if [ "$(basename $i .1.dar)" = "$SOURCE_FILE" ]; then
        break
    fi
done

echo "done."
