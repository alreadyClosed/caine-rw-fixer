# caine rw fixer
 
Fixes CAINE Linux booting into read-only mode on persistent dual-boot installations, preventing the desktop environment from loading.
 
## Usage
 
First, remount the root partition as read-write so you can run the script:
 
```
sudo mount -o remount,rw /
```
 
Wait for the desktop to appear, then run:
 
```bash
chmod +x caine_rw_fixer.sh
sudo ./caine_rw_fixer.sh
```

Or if you have internet access:

```
curl -fsSL https://raw.githubusercontent.com/alreadyClosed/caine-rw-fixer/refs/heads/main/caine_rw_fixer.sh | sudo bash
```

> ⚠️ **Warning:** The script will reboot your system when done.

# Internet troubleshooting

If you get the "failure adding connection settings plugin does not support adding connections" error then run:

```
cat /etc/NetworkManager/NetworkManager.conf | grep managed
```
if it says "managed=false" then edit it and change it to true:

```
sudo nano /etc/NetworkManager/NetworkManager.conf
```

The system will reboot automatically when done.
 
