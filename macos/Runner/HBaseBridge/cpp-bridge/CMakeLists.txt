cmake_minimum_required(VERSION 3.10)
project(hbase_bridge)

# 设置C++标准
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 查找Java
find_package(JNI REQUIRED)
include_directories(${JNI_INCLUDE_DIRS})

# 添加源文件
set(SOURCES
    src/main/cpp/hbase_bridge.cpp
)

# 创建共享库
add_library(hbase_bridge SHARED ${SOURCES})

# 设置输出名称
set_target_properties(hbase_bridge PROPERTIES
    OUTPUT_NAME "hbase_bridge"
    PREFIX ""
)

# 链接Java库
target_link_libraries(hbase_bridge ${JNI_LIBRARIES})

# 设置安装路径
install(TARGETS hbase_bridge
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
) 