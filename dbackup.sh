#!/usr/bin/env bash

NO_COMPRESS=(
    "7z"  "ace" "ape"   "apk"  "arc" "arj" "avi" 
    "bz2" "cap" "dar"   "deb"  "dmg" "exe" "flac"
    "flv" "gz"  "ha"    "ice"  "iso" "jar" "jpg"  "jpeg"
    "lha" "lz"  "lzh"   "lzma" "lzo" 
    "m4a" "m4v" "mkv"   "mov"  "mp3" "mp4" "ogg"
    "pak" "png" "rar"   "rpm"  "rz" 
    "s7z" "sea" "sfark" "sit"  "sitx" "sqx" "sz"
    "tbz" "tgz" "txz"
    "wmv" "xz"  "zip"   "zoo" "zz"
)

NAME=""
SOURCE=""
TARGET=""
SKIP=0

function showusage {
    echo "usage: $(basename $0) [arguments]

-s, --source    The directory to compress.
-t, --target    Optional target directory. Defaults to the parent directory
                of the specified root directory, but cannot be the same.
-n, --name      Optional name. Defaults to the name of the specified root
                directory.
    --skip      Skip test of created archive.
-h, --help      Display this usage information.
"
}

if [ "$1" = "" ]; then
    showusage
    exit 1
fi

while [[ "$1" != "" ]]; do
    case $1 in
        -s|--source)
            if [ ! -d "$2" ]; then
                echo "specified source is not a directory or directory not found"
                exit 1
            fi
            
            SOURCE="$(cd "$2" && echo $PWD)"
            shift
            ;;
        -t|--target)
            if [ ! -d "$2" ]; then
                echo "specified target is not a directory or directory not found"
                exit 1
            fi
            
            TARGET="$(cd "$2" && echo $PWD)"
            shift
            ;;
        -n|--name)
            NAME="$2"
            shift
            ;;
        --skip)
            SKIP=1
            ;;
        -h|-\?|--help)
            showusage
            exit 1
            ;;
        *)
            echo "unknown argument"
            exit 1
            ;;
    esac

    shift
done

if [ "$SOURCE" = "" ]; then
    echo "no source directory specified"
    exit 1
elif [ "$SOURCE" = "/" ] && [ "$NAME" = "" ]; then
    echo "argument -n is mandatory if source points to the root directory"
    exit 1
fi

if [ "$TARGET" != "" ]; then
    if [ ! -d "$TARGET" ]; then
        echo "specified target is not a directory or directory not found"
        exit 1
    fi
else
    TARGET=$(dirname "$SOURCE")
fi

if [ "$TARGET" -ef "$SOURCE" ]; then
    echo "root and target directory cannot be the same"
    exit 1
fi

if [ "$NAME" = "" ]; then
    NAME="$(basename "$SOURCE")"
fi

PREV=$(ls -1 $TARGET/$NAME""_*_*.1.dar 2>/dev/null | egrep '(base|diff).1.dar$' | sort | tail -n 1)

if [ "$PREV" != "" ]; then
    PREV=$(dirname $PREV)/$(basename $PREV .1.dar)
    INCR="-A $PREV"
    PFIX="_diff"
else
    PREV=""
    INCR=""
    PFIX="_base"
fi

NAME="$NAME""_$(date -u +"%Y-%m-%dT%H:%M:%SZ")$PFIX"
FILE="$TARGET/$NAME"

echo "Creating archive: $FILE"
echo "            from: $SOURCE"

if [ "$PREV" != "" ]; then
    echo "        previous: $PREV"
fi

# @see http://dar.sourceforge.net/doc/mini-howto/dar-differential-backup-mini-howto.en.html#making-a-full-backup-with-dar
# for usage details
Z=""

for i in "${NO_COMPRESS[@]}"; do
    Z="$Z -Z \"*.$i\""
done

dar -m 256 -zbzip2 -y -s 1000G -R "$SOURCE" -c "$FILE" $Z $INCR #> /dev/null
err=$?

if [ $err -ne 0 ]; then
    echo "Archive creation FAILED"
    exit $err
fi

if [ $SKIP -eq 1 ]; then
    echo "Archive created"
    exit 0
else
    dar -t "$FILE" > /dev/null
    err=$?

    if [ $err -ne 0 ]; then
        echo "Archive created but test FAILED"
        exit $err
    else
        echo "Archive created and successfully tested"
        exit 0
    fi
fi
