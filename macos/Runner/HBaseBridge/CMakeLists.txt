cmake_minimum_required(VERSION 3.10)
project(hbase_bridge)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 查找JNI
find_package(JNI REQUIRED)
include_directories(${JNI_INCLUDE_DIRS})

# 添加源文件
add_library(hbase_bridge SHARED
    src/main/cpp/hbase_bridge.cpp
)

# 链接JNI库
target_link_libraries(hbase_bridge
    ${JNI_LIBRARIES}
) 