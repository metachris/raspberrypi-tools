#!/bin/bash
set -e
#
# Restore the content of a gzipped (or zipped) image file onto a SD card
#
# https://github.com/metachris/raspberrypi-tools
#

if [ -z "$1" ]; then
    echo "Use: $0 <img.gz-fn> [<diskN>]"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "'$1' not found"
    exit 1
fi


function find_sd_card_reader_device() {
    DISKS=$( diskutil list | grep ^/dev/disk[2-9] | awk '{ print $1 }' )
    for disk in $DISKS; do
        STATUS=$( diskutil info $disk | grep "SD Card Reader" )
        if [[ $STATUS ]]; then echo "$disk" | sed s:/dev/::g; exit 0; fi
    done
}

if [ -n "$2" ]; then
    DEV=$2
else
    DEV=$( find_sd_card_reader_device )
    echo "FOUND SD Card Reader at /dev/$DEV"
fi

if [ -z "$( diskutil list | grep /dev/$DEV )" ]; then
    echo "Device '$DEV' not found"
    exit 1
fi

#diskutil list
diskutil info $DEV

echo
read -p "Will overwrite '/dev/$DEV'. Are you sure? [y/N] " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # do dangerous stuff
    sudo diskutil unmountDisk /dev/$DEV

    echo "Writing image to SD card..."

    if [[ $1 =~ \.gz$ ]]
    then
        pv $1 | gzip -dc | sudo dd of=/dev/r$DEV bs=1M
    elif [[ $1 =~ \.img$ ]]
    then
        pv $1 | sudo dd of=/dev/r$DEV bs=1M
    else
        print "Error: cannot extract file - unknown type (only .gz/.img are supported)"
        exit 1
    fi

    echo "Syncing..."
    sync

    diskutil unmountDisk /dev/$DEV
    echo "All done!"
    say "the sd card is ready"
fi
