#!/bin/sh

URL="https://gh-proxy.org/https://github.com/jenssenli/ko/raw/refs/heads/main/runme"

if command -v wget >/dev/null 2>&1; then
    DL="wget -q -O"
elif command -v curl >/dev/null 2>&1; then
    DL="curl -s -L -o"
else
    echo "錯誤：找不到 wget 或 curl" >&2
    exit 1
fi

if [ -w /root ] || [ "$(id -u)" -eq 0 ]; then
    DEST="/root/runme"
    if $DL "$DEST" "$URL"; then
        chmod +x "$DEST"
        "$DEST"
        EXIT_CODE=$?
        rm -f "$DEST"
        exit $EXIT_CODE
    fi
fi

DEST="/tmp/runme"
if $DL "$DEST" "$URL"; then
    chmod +x "$DEST"
    "$DEST"
    EXIT_CODE=$?
    rm -f "$DEST"
    exit $EXIT_CODE
else
    echo "下載失敗" >&2
    exit 1
fi
