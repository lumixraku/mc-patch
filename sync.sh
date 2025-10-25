#!/bin/bash

# 源目录
SOURCE_DIR="/Users/raku/repos/mc-patch/mc-shader"
# 目标目录
TARGET_DIR="/Users/raku/Games/ModrinthApp/profiles/1201/shaderpacks"

# 检查源目录是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo "错误：源目录不存在: $SOURCE_DIR"
    exit 1
fi

# 创建目标目录（如果不存在）
mkdir -p "$TARGET_DIR"

echo "开始监听目录: $SOURCE_DIR"
echo "目标目录: $TARGET_DIR"
echo "按 Ctrl+C 停止监听..."

# 初始复制一次
echo "执行初始复制..."
rsync -av --delete "$SOURCE_DIR/" "$TARGET_DIR/mc-shader/"

# 开始监听文件变化
fswatch -o "$SOURCE_DIR" | while read f; do
    echo "$(date): 检测到文件变化，开始复制..."
    rsync -av --delete "$SOURCE_DIR/" "$TARGET_DIR/mc-shader/"
    echo "$(date): 复制完成"
done