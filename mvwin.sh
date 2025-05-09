#!/bin/bash

DEFAULT_USER="tarik"
DEFAULT_IP="192.168.1.6"
WINDOWS_DEST_PATH="C:\\Users\\$DEFAULT_USER\\Downloads"

FILE="$1"
USER="${2:-$DEFAULT_USER}"
IP="${3:-$DEFAULT_IP}"

if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  echo "Usage: $0 <file> [user] [ip]"
  echo "Example: $0 myapp.exe winuser 192.168.1.123"
  exit 1
fi

echo "[*] Uploading $FILE to $USER@$IP..."
scp "$FILE" "$USER@$IP:/C:/Users/$USER/Downloads/" || {
  echo "[!] File transfer failed."
  exit 2
}
echo "[✓] Done."
