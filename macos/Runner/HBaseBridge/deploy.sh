#!/bin/bash

# 确保脚本在失败时立即退出
set -e

echo "开始构建HBase桥接库..."

# 清理并构建所有组件
./gradlew clean buildAll

# 检查构建结果
if [ $? -eq 0 ]; then
  echo "构建成功!"
  
  # 复制JAR文件到Flutter应用可访问的位置
  mkdir -p ../assets
  cp java-bridge/build/libs/java-bridge.jar ../assets/
  echo "Java库已复制到assets目录"
  
  # 检查动态库是否已成功复制
  if [ -f "../Frameworks/libhbase_bridge.dylib" ]; then
    echo "C++动态库已成功部署到Frameworks目录"
    
    # 显示文件信息
    ls -la ../Frameworks/libhbase_bridge.dylib
    
    echo "部署完成，可以在Flutter应用中使用HBase桥接库了!"
  else
    echo "错误: 动态库未成功复制"
    exit 1
  fi
else
  echo "构建失败!"
  exit 1
fi 