#!/bin/bash

# 创建构建目录
mkdir -p build
cd build

# 配置CMake
cmake ..

# 构建项目
make

# 创建Frameworks目录（如果不存在）
mkdir -p ../../../Frameworks

# 复制动态库到Frameworks目录
cp hbase_bridge.dylib ../../../Frameworks/

echo "构建完成！动态库已复制到 Frameworks 目录。" 