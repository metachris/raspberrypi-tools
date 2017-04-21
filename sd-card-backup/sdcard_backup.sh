#!/bin/bash
#
# Backup the SD card content to a local gzipped image file
#
# https://github.com/metachris/raspberrypi-tools
#
COUNT=3072

while [[ "$#" > 0 ]]; do case $1 in
    -n)
        # Number of blocks
        COUNT=$2
        if [[ -z $COUNT ]]; then
            echo "Please specify a number of MB with the -n argument";
            exit 1
        fi
        shift; shift
        ;;
    -i)
        # Input device
        i=$2
        if [[ -z $i ]]; then
            echo "Please specify an input device with the -i argument";
            exit 1
        fi
        shift; shift
        ;;
    -o)
        # Output file
        o=$2
        if [[ -z $o ]]; then
            echo "Please specify an output file";
            exit 1
        fi
        shift; shift
        ;;
    *) break;;
  esac;
done

if [ -z "$o" ]; then
    echo "Use: $0 -o <img.gz-fn> [-i <diskN>] [-n <block-count>]"
    exit 1
fi

if [ -f "$o" ]; then
    echo "Error: '$o' already exists."
    exit 1
fi

function find_sd_card_reader_device() {
    DISKS=$( diskutil list | grep ^/dev/disk[1-9] | awk '{ print $1 }' )
    for disk in $DISKS; do
        #echo $disk
        STATUS=$( diskutil info $disk | grep "SD Card Reader" )
        if [[ $STATUS ]]; then echo "$disk" | sed s:/dev/::g; fi
    done
}

if [ -n "$i" ]; then
    DEV=$i
else
    DEV=$( find_sd_card_reader_device )
fi

if [ -z $DEV ]; then
    echo "Error: could not find sd card reader device"
    exit 1
fi

if [ -z "$( diskutil list | grep $DEV )" ]; then
    echo "Device '$DEV' not found"
    exit 1
fi

#diskutil list

echo
echo "Backing up from this disk:"
diskutil info $DEV

echo
read -p "Will backup $COUNT MB of '/dev/$DEV' to '$o'. Are you sure? [y/N] " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # do dangerous stuff
    diskutil unmountDisk /dev/$DEV
    sudo dd if=/dev/r$DEV bs=1M count=$COUNT status=progress | gzip > $o
    diskutil unmountDisk /dev/$DEV
fi

say "Backup of the SD card is complete"
