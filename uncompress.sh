#!/usr/bin/env bash

if [ "$2" = "" ]; then
    echo "usage: $(basename $0) <source-base-file> <target-dir>"
    exit 1
fi

NUM=$(ls -1 $1_*_base.1.dar 2>/dev/null | wc -l)

if [ $NUM -eq 0 ]; then
    echo "base file not found for $1"
    exit 1
elif [ $NUM -ne 1 ]; then
    echo "ambigous base file for $1"
    exit 1
fi

if [ ! -d "$2" ]; then
    echo "target directory does not exist"
    exit 1
fi

TARGET=$2/$(basename $1 .1.dar)

if [ -e "$TARGET" ]; then
    echo "target path already exists"
    exit 1
fi

mkdir "$TARGET"

for i in $(ls -1 "$1"_*_base.1.dar 2>/dev/null) $(ls -1 $1_*_diff.1.dar 2>/dev/null); do
    echo "Exctracting $i"
    
    dar -x "$(dirname $i)/$(basename $i .1.dar)" -O -w -R "$TARGET"
done

echo "done."
