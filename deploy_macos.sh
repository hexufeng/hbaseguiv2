#!/bin/bash

# 设置路径
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE_DYLIB="${PROJECT_DIR}/macos/Runner/Frameworks/libhbase_bridge.dylib"
SOURCE_JAR="${PROJECT_DIR}/macos/Runner/HBaseBridge/java-bridge/build/libs/java-bridge.jar"
TARGET_APP_FRAMEWORKS="${PROJECT_DIR}/build/macos/Build/Products/Debug/hbaseguiv2.app/Contents/Frameworks"
TARGET_APP_RESOURCES="${PROJECT_DIR}/build/macos/Build/Products/Debug/hbaseguiv2.app/Contents/Resources"
APP_PATH="${PROJECT_DIR}/build/macos/Build/Products/Debug/hbaseguiv2.app"

# 输出当前目录和文件位置
echo "部署HBase Bridge动态库到应用程序包"
echo "项目目录: ${PROJECT_DIR}"
echo "动态库源路径: ${SOURCE_DYLIB}"
echo "Java JAR源路径: ${SOURCE_JAR}"
echo "目标应用Frameworks路径: ${TARGET_APP_FRAMEWORKS}"
echo "目标应用Resources路径: ${TARGET_APP_RESOURCES}"

# 确保目标目录存在
mkdir -p "${TARGET_APP_FRAMEWORKS}"
mkdir -p "${TARGET_APP_RESOURCES}"

# 复制动态库
if [ -f "${SOURCE_DYLIB}" ]; then
  echo "复制动态库到应用包内的Frameworks目录..."
  cp "${SOURCE_DYLIB}" "${TARGET_APP_FRAMEWORKS}/"
  echo "动态库复制成功!"
else
  echo "错误: 找不到源动态库: ${SOURCE_DYLIB}"
  exit 1
fi

# 复制Java JAR文件
if [ -f "${SOURCE_JAR}" ]; then
  echo "复制Java JAR文件到应用包内的Resources目录..."
  cp "${SOURCE_JAR}" "${TARGET_APP_RESOURCES}/"
  echo "Java JAR文件复制成功!"
else
  echo "错误: 找不到源JAR文件: ${SOURCE_JAR}"
  exit 1
fi

# 签名动态库
echo "为动态库签名..."
codesign --force --sign - "${TARGET_APP_FRAMEWORKS}/libhbase_bridge.dylib"

# 显示复制后的文件
echo -e "\n验证文件复制:"
ls -la "${TARGET_APP_FRAMEWORKS}/libhbase_bridge.dylib"
ls -la "${TARGET_APP_RESOURCES}/java-bridge.jar"

echo -e "\n部署完成! 应用程序应该能够找到动态库了。"
echo "提示: 如果构建失败，请尝试以下命令重新构建应用:"
echo "flutter clean"
echo "flutter run -d macos" 