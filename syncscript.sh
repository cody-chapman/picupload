    MOUNT_POINT="/mnt/Pictures"
    TEMP_POINT="/mnt/temp-$(uuidgen)"
    SOURCE_DIR="/home/vnaftp"

    echo "domain=$(cat /run/secrets/domain)" > /etc/cifs.creds
    echo "username=$(cat /run/secrets/domainusername)" >> /etc/cifs.creds
    echo "password=$(cat /run/secrets/domainpassword)" >> /etc/cifs.creds

    # 1. Mount Check & Recovery Logic
    if ! findmnt -t cifs "$MOUNT_POINT" >/dev/null 2>&1; then
        echo "CIFS not detected, attempting recovery mount..."
        mkdir -p "$TEMP_POINT"
        cp -fR "$MOUNT_POINT"/* "$TEMP_POINT" 2>/dev/null
        rm -fR "$MOUNT_POINT"
        mkdir -p "$MOUNT_POINT"
        mount -t cifs -o credentials=/etc/cifs.creds //vnafs/Pictures /mnt/Pictures
        if [ $? -eq 0 ]; then
            cp -fR "$TEMP_POINT"/* "$MOUNT_POINT" 2>/dev/null
            rm -fR "$TEMP_POINT"
        else
            echo "Mount failed! Aborting sync to prevent data loss."
            exit 1
        fi
    fi

    # 2. File Conversion and Move Logic
    cd "$SOURCE_DIR"
    # Find JPGs, convert to PDF, then delete JPGs
    find . -maxdepth 1 -iname "*.jpg" -exec mogrify -format pdf {} \; -exec rm -f {} \;

    # Move all files (PDFs and others) to mount and clear source
    # We use -mindepth 1 to avoid moving the directory itself
    find . -mindepth 1 -maxdepth 1 -exec cp -fR {} "$MOUNT_POINT/" \; -exec rm -rf {} \;
