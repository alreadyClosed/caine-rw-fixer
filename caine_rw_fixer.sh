#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Please run as root: sudo ./CAINE_RW_FIXER.sh"
    exit 1
fi

echo "============================================"
echo "           CAINE Read-Write Fixer           "
echo "============================================"
echo ""

ROOT_PART=$(findmnt -n -o SOURCE /)
echo "[INFO] Detected root partition: $ROOT_PART"
echo ""

echo "[STEP 1/3] Checking /etc/fstab for read-only root entry..."
if grep -qP "^\S+\s+/\s+\S+\s+[^#]*\bro\b" /etc/fstab; then
    echo "  [!] Found 'ro' flag in fstab for root partition. Fixing..."
    cp /etc/fstab /etc/fstab.bak
    sed -i -E '/^\S+\s+\/\s+/s/\bro\b/rw/' /etc/fstab
    echo "  [OK] Fixed. Backup saved to /etc/fstab.bak"
else
    echo "  [OK] fstab root entry looks fine."
fi
echo ""

echo "[STEP 2/3] Checking swap configuration..."
SWAP_PART=$(blkid | grep swap | awk '{print $1}' | sed 's/://' | head -1)
if grep -q "/swapfile" /etc/fstab && [ ! -f /swapfile ]; then
    echo "  [!] fstab references /swapfile but it doesn't exist."
    if [ -n "$SWAP_PART" ]; then
        echo "  [INFO] Found swap partition: $SWAP_PART"
        echo "  [INFO] Updating fstab to use swap partition instead..."
        cp /etc/fstab /etc/fstab.bak2
        sed -i '/\/swapfile/d' /etc/fstab
        echo "$SWAP_PART    none    swap    sw    0    0" >> /etc/fstab
        swapon "$SWAP_PART" 2>/dev/null && echo "  [OK] Swap activated on $SWAP_PART" || echo "  [WARN] Could not activate swap right now, will work after reboot."
    else
        echo "  [WARN] No swap partition found. Skipping swap fix."
    fi
else
    echo "  [OK] Swap configuration looks fine."
fi
echo ""

echo "[STEP 3/3] Creating systemd service to force rw on boot..."
SERVICE_PATH="/etc/systemd/system/setrw-root.service"
printf '[Unit]\nDescription=Set root partition read-write early on boot\nDefaultDependencies=no\nBefore=local-fs.target\n\n[Service]\nType=oneshot\nExecStart=/sbin/blockdev --setrw %s\nExecStart=/bin/mount -o remount,rw /\n\n[Install]\nWantedBy=local-fs.target\n' "$ROOT_PART" > "$SERVICE_PATH"
echo "  [OK] Service file created at $SERVICE_PATH"

systemctl daemon-reload
systemctl enable setrw-root.service
echo "  [OK] Service enabled."
echo ""

echo "============================================"
echo " All done! Rebooting in..."
echo "============================================"

for i in 3 2 1; do
    echo "  $i..."
    sleep 1
done

reboot
