#!/bin/bash

check_tools() {
    if ! command -v parted &> /dev/null; then
        echo "Error: parted is not installed. Please install it using your package manager."
        exit 1
    fi
    if ! command -v mkfs.fat &> /dev/null; then
        echo "Error: mkfs.fat is not installed. Please install it using your package manager."
        exit 1
    fi
    if ! command -v mkfs.ext4 &> /dev/null; then
        echo "Error: mkfs.ext4 is not installed. Please install it using your package manager."
        exit 1
    fi
}

get_sdcard() {
    echo "Detecting SD card..."
    lsblk
    echo -n "Enter the SD card device path (e.g., /dev/sdX or /dev/mmcblk0): "
    read SDCARD

    if [ ! -b "$SDCARD" ]; then
        echo "Error: $SDCARD is not a valid block device."
        exit 1
    fi

    echo "SD card selected: $SDCARD"
}

create_partitions() {
    echo "Creating partitions on $SDCARD..."

    # Remove existing partitions (Warning: This erases data!)
    sudo parted "$SDCARD" --script -- mklabel msdos

    # Create BOOT partition (150 MB, FAT32, boot flag)
    sudo parted "$SDCARD" --script -- mkpart primary fat32 1MiB 151MiB
    sudo parted "$SDCARD" --script -- set 1 boot on

    # Force re-reading the partition table
    sudo partprobe "$SDCARD"

    # Create ROOT partition (remaining space, ext4)
    sudo parted "$SDCARD" --script -- mkpart primary ext4 151MiB 100%

    # Force re-reading the partition table again
    sudo partprobe "$SDCARD"

    echo "Partitions created successfully."
}

format_partitions() {
    echo "Formatting partitions..."

    # Wait for system to recognize the new partitions
    sleep 2

    # Determine if we are dealing with mmcblk or sdX device types
    if [[ "$SDCARD" == *"mmcblk"* ]]; then
        BOOT_PART="${SDCARD}p1"
        ROOT_PART="${SDCARD}p2"
    else
        BOOT_PART="${SDCARD}1"
        ROOT_PART="${SDCARD}2"
    fi

    # Format BOOT partition (FAT32)
    sudo mkfs.fat -F32 "$BOOT_PART" -n BOOT

    # Format ROOT partition (ext4)
    sudo mkfs.ext4 "$ROOT_PART" -L ROOT

    echo "Partitions formatted successfully."
}

# Main script logic
check_tools
get_sdcard
create_partitions
format_partitions

echo "SD card partitioning and formatting completed."
