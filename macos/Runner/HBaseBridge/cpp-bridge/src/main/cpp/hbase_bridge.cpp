#include "hbase_bridge.h"
#include <iostream>
#include <string>
#include <exception>
#include <vector>
#include <map>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <errno.h>
#include <pthread.h>
#include <jni.h>

static JavaVM* jvm = nullptr;
static jobject bridgeInstance = nullptr;
static bool jvmInitialized = false;

// 全局变量
JavaVM* g_jvm = nullptr;
JNIEnv* g_env = nullptr;
jclass g_hbaseBridgeClass = nullptr;
jobject g_hbaseBridgeInstance = nullptr;

extern "C" {

// 初始化JVM
JNIEXPORT bool JNICALL initJVM() {
    try {
        std::cout << "【关键诊断】initJVM 函数开始执行，进程ID: " << getpid() << std::endl;
        std::cout << "【关键诊断】系统信息: " << std::flush;
        system("uname -a");
        
        // 打印当前线程ID
        std::cout << "【线程追踪】当前线程ID: " << pthread_self() << std::endl;
        fflush(stdout);
        
        // 设置HADOOP_USER_NAME环境变量
        std::cout << "尝试在JVM初始化前设置环境变量 HADOOP_USER_NAME=da_music" << std::endl;
        if (setenv("HADOOP_USER_NAME", "da_music", 1) != 0) {
            std::cerr << "在initJVM中设置环境变量失败: " << strerror(errno) << std::endl;
            // 继续执行
        } else {
            std::cout << "在initJVM中成功设置环境变量 HADOOP_USER_NAME=da_music" << std::endl;
        }
        
        // 安全检查当前工作目录
        char cwd[1024];
        if (getcwd(cwd, sizeof(cwd)) != NULL) {
            std::cout << "【诊断信息】当前工作目录: " << cwd << std::endl;
        }
        
        // 如果JVM已初始化，直接返回
        if (jvmInitialized && jvm != nullptr) {
            std::cout << "JVM已经初始化，直接使用" << std::endl;
            return true;
        }
        
        // 先检查是否可以获取已有JVM
        JNIEnv* existing_env = nullptr;
        jsize vm_count = 0;
        
        // 查询已存在的JavaVMs
        if (JNI_GetCreatedJavaVMs(&jvm, 1, &vm_count) == JNI_OK && vm_count > 0 && jvm != nullptr) {
            std::cout << "找到已存在的JVM实例，尝试使用" << std::endl;
            
            // 尝试附加到现有JVM
            jint attach_result = jvm->GetEnv((void**)&existing_env, JNI_VERSION_1_8);
            if (attach_result == JNI_EDETACHED) {
                // 线程未附加到JVM，尝试附加
                if (jvm->AttachCurrentThread((void**)&existing_env, nullptr) == JNI_OK && existing_env != nullptr) {
                    std::cout << "成功附加到现有JVM" << std::endl;
                    jvmInitialized = true;
                    return true;
                }
            } else if (attach_result == JNI_OK && existing_env != nullptr) {
                // 已附加到JVM
                std::cout << "已经附加到现有JVM" << std::endl;
                jvmInitialized = true;
                return true;
            }
        }
        
        std::cout << "需要创建新的JVM实例..." << std::endl;
        
        // 尝试多个可能的路径
        std::vector<std::string> jarPaths = {
            // 应用程序内部资源路径
            "../Resources/java-bridge.jar",
            "../../Resources/java-bridge.jar",
            "./Resources/java-bridge.jar",
            // 可执行文件当前目录
            "./java-bridge.jar",
            // 绝对路径 - 已构建的应用程序包
            "/Users/hexufeng/Library/Containers/com.example.hbaseguiv2/Data/macos/Runner/Resources/java-bridge.jar",
            "/Users/hexufeng/Learn/MacAPP/hbaseguiv2/build/macos/Build/Products/Debug/hbaseguiv2.app/Contents/Resources/java-bridge.jar",
            // 开发环境路径
            "/Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/HBaseBridge/java-bridge/build/libs/java-bridge.jar"
        };
        
        std::string jarPath;
        bool jarFound = false;
        
        for (const auto& path : jarPaths) {
            std::cout << "尝试JAR路径: " << path << std::endl;
            FILE* file = fopen(path.c_str(), "r");
            if (file) {
                std::cout << "找到JAR文件: " << path << std::endl;
                fclose(file);
                jarPath = path;
                jarFound = true;
                break;
            } else {
                std::cout << "未找到JAR文件: " << path << " (错误: " << strerror(errno) << ")" << std::endl;
            }
        }
        
        if (!jarFound) {
            std::cerr << "无法找到必要的JAR文件" << std::endl;
            return false;
        }
        
        // JVM初始化参数
        JavaVMInitArgs vm_args;
        JavaVMOption options[12]; // 增加选项数量
        
        // 设置类路径
        std::string classpath = "-Djava.class.path=";
        classpath += jarPath;
        options[0].optionString = const_cast<char*>(classpath.c_str());
        
        // 设置其他JVM选项
        options[1].optionString = const_cast<char*>("-Djava.library.path=.");
        options[2].optionString = const_cast<char*>("-Dfile.encoding=UTF-8");
        options[3].optionString = const_cast<char*>("-Xcheck:jni");
        options[4].optionString = const_cast<char*>("-Xmx512m");
        options[5].optionString = const_cast<char*>("-verbose:jni"); // 添加JNI详细日志
        options[6].optionString = const_cast<char*>("-verbose:class"); // 添加类加载日志
        
        // 添加HADOOP_USER_NAME系统属性
        std::string hadoopUserProp = "-DHADOOP_USER_NAME=da_music";
        options[7].optionString = const_cast<char*>(hadoopUserProp.c_str());
        
        // 额外的Hadoop相关设置
        options[8].optionString = const_cast<char*>("-Dhadoop.home.dir=/tmp");
        options[9].optionString = const_cast<char*>("-Djava.security.krb5.realm=");
        options[10].optionString = const_cast<char*>("-Djava.security.krb5.kdc=");
        options[11].optionString = const_cast<char*>("-Djava.awt.headless=true");
        
        vm_args.version = JNI_VERSION_1_8;
        vm_args.nOptions = 12; // 更新选项数量
        vm_args.options = options;
        vm_args.ignoreUnrecognized = JNI_TRUE;
        
        std::cout << "【JVM初始化】创建JVM，类路径: " << classpath << std::endl;
        std::cout << "【JVM初始化】HADOOP_USER_NAME设置为: da_music" << std::endl;
        std::cout << "【JVM初始化】JVM版本: " << JNI_VERSION_1_8 << std::endl;
        std::cout << "【JVM初始化】JVM选项数量: " << vm_args.nOptions << std::endl;
        
        // 创建JVM
        JNIEnv* env;
        jint res = JNI_CreateJavaVM(&jvm, (void**)&env, &vm_args);
        if (res != JNI_OK) {
            std::cerr << "【JVM初始化】创建JVM失败，错误码: " << res << std::endl;
            return false;
        }
        
        std::cout << "【JVM初始化】JVM创建成功" << std::endl;
        
        // 验证是否可以加载类
        jclass testClass = env->FindClass("java/lang/String");
        if (testClass == nullptr) {
            std::cerr << "无法加载基本Java类，JVM配置有问题" << std::endl;
            if (env->ExceptionCheck()) {
                env->ExceptionDescribe();
                env->ExceptionClear();
            }
            jvm = nullptr;
            return false;
        }
        
        std::cout << "基本Java类加载成功，尝试加载自定义类..." << std::endl;
        
        // 尝试加载HBaseBridge类
        jclass hbaseBridgeClass = env->FindClass("com/hbasegui/bridge/HBaseBridge");
        if (hbaseBridgeClass == nullptr) {
            std::cerr << "无法加载HBaseBridge类" << std::endl;
            if (env->ExceptionCheck()) {
                env->ExceptionDescribe();
                env->ExceptionClear();
            }
            env->DeleteLocalRef(testClass);
            jvm = nullptr;
            return false;
        }
        
        std::cout << "HBaseBridge类加载成功，JVM环境正常" << std::endl;
        
        // 检查环境变量是否成功设置在JVM中
        jclass systemClass = env->FindClass("java/lang/System");
        if (systemClass != nullptr) {
            jmethodID getPropertyMethod = env->GetStaticMethodID(systemClass, "getProperty", 
                "(Ljava/lang/String;)Ljava/lang/String;");
            if (getPropertyMethod != nullptr) {
                jstring propName = env->NewStringUTF("HADOOP_USER_NAME");
                jstring propValue = (jstring)env->CallStaticObjectMethod(systemClass, getPropertyMethod, propName);
                
                if (propValue != nullptr) {
                    const char* valueStr = env->GetStringUTFChars(propValue, nullptr);
                    std::cout << "JVM中的HADOOP_USER_NAME属性值: " << valueStr << std::endl;
                    env->ReleaseStringUTFChars(propValue, valueStr);
                    env->DeleteLocalRef(propValue);
                } else {
                    std::cout << "JVM中的HADOOP_USER_NAME属性未设置" << std::endl;
                    
                    // 尝试在JVM创建后设置
                    jmethodID setPropertyMethod = env->GetStaticMethodID(systemClass, "setProperty", 
                        "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;");
                    if (setPropertyMethod != nullptr) {
                        jstring propNameSet = env->NewStringUTF("HADOOP_USER_NAME");
                        jstring propValueSet = env->NewStringUTF("da_music");
                        env->CallStaticObjectMethod(systemClass, setPropertyMethod, propNameSet, propValueSet);
                        std::cout << "已在JVM创建后设置HADOOP_USER_NAME=da_music" << std::endl;
                        env->DeleteLocalRef(propNameSet);
                        env->DeleteLocalRef(propValueSet);
                    }
                }
                
                env->DeleteLocalRef(propName);
            }
            env->DeleteLocalRef(systemClass);
        }
        
        env->DeleteLocalRef(hbaseBridgeClass);
        env->DeleteLocalRef(testClass);
        
        jvmInitialized = true;
        return true;
    } catch (const std::exception& e) {
        std::cerr << "JVM初始化过程中发生异常: " << e.what() << std::endl;
        jvm = nullptr;
        jvmInitialized = false;
        return false;
    } catch (...) {
        std::cerr << "JVM初始化过程中发生未知异常" << std::endl;
        jvm = nullptr;
        jvmInitialized = false;
        return false;
    }
}

JNIEXPORT bool JNICALL connect(const char* zkQuorum, const char* zkNode) {
    try {
        std::cout << "【关键诊断】connect 函数开始执行，进程ID: " << getpid() << std::endl;
        std::cout << "【线程追踪】连接方法线程ID: " << pthread_self() << std::endl;
        fflush(stdout);
        
        // 检查参数
        if (zkQuorum == nullptr || zkNode == nullptr) {
            std::cerr << "C++ bridge: connect() 参数无效 (空指针)" << std::endl;
            return false;
        }
        
        // 检查JVM状态
        if (!jvmInitialized || jvm == nullptr) {
            std::cerr << "JVM未初始化，尝试初始化..." << std::endl;
            if (!initJVM()) {
                std::cerr << "JVM初始化失败" << std::endl;
                return false;
            }
        }
        
        // 获取JNIEnv
        JNIEnv* env = nullptr;
        jint getEnvResult = jvm->GetEnv((void**)&env, JNI_VERSION_1_8);
        
        if (getEnvResult == JNI_EDETACHED) {
            if (jvm->AttachCurrentThread((void**)&env, nullptr) != JNI_OK) {
                std::cerr << "无法附加到JVM线程" << std::endl;
                return false;
            }
        } else if (getEnvResult != JNI_OK) {
            std::cerr << "无法获取JNIEnv" << std::endl;
            return false;
        }
        
        // 获取HBaseBridge类
        jclass bridgeClass = env->FindClass("com/hbasegui/bridge/HBaseBridge");
        if (bridgeClass == nullptr) {
            std::cerr << "无法找到HBaseBridge类" << std::endl;
            if (env->ExceptionCheck()) {
                env->ExceptionDescribe();
                env->ExceptionClear();
            }
            return false;
        }
        
        // 获取connect方法
        jmethodID connectMethod = env->GetStaticMethodID(bridgeClass, "connect", 
            "(Ljava/lang/String;Ljava/lang/String;)Z");
        if (connectMethod == nullptr) {
            std::cerr << "无法找到connect方法" << std::endl;
            if (env->ExceptionCheck()) {
                env->ExceptionDescribe();
                env->ExceptionClear();
            }
            env->DeleteLocalRef(bridgeClass);
            return false;
        }
        
        // 创建Java字符串参数
        jstring zkQuorumStr = env->NewStringUTF(zkQuorum);
        jstring zkNodeStr = env->NewStringUTF(zkNode);
        
        if (zkQuorumStr == nullptr || zkNodeStr == nullptr) {
            std::cerr << "无法创建Java字符串参数" << std::endl;
            if (zkQuorumStr != nullptr) env->DeleteLocalRef(zkQuorumStr);
            if (zkNodeStr != nullptr) env->DeleteLocalRef(zkNodeStr);
            env->DeleteLocalRef(bridgeClass);
            return false;
        }
        
        // 调用Java方法
        jboolean result = env->CallStaticBooleanMethod(bridgeClass, connectMethod, zkQuorumStr, zkNodeStr);
        
        // 检查是否有异常发生
        if (env->ExceptionCheck()) {
            std::cerr << "Java方法执行过程中发生异常" << std::endl;
            env->ExceptionDescribe();
            env->ExceptionClear();
            env->DeleteLocalRef(zkQuorumStr);
            env->DeleteLocalRef(zkNodeStr);
            env->DeleteLocalRef(bridgeClass);
            return false;
        }
        
        // 清理引用
        env->DeleteLocalRef(zkQuorumStr);
        env->DeleteLocalRef(zkNodeStr);
        env->DeleteLocalRef(bridgeClass);
        
        return result;
    } catch (const std::exception& e) {
        std::cerr << "连接过程中发生异常: " << e.what() << std::endl;
        return false;
    } catch (...) {
        std::cerr << "连接过程中发生未知异常" << std::endl;
        return false;
    }
}

JNIEXPORT const char* JNICALL getTables() {
    try {
        // 检查JVM状态
        if (!jvmInitialized || jvm == nullptr) {
            std::cerr << "JVM未初始化" << std::endl;
            return nullptr;
        }
        
        // 获取JNIEnv
        JNIEnv* env = nullptr;
        jint getEnvResult = jvm->GetEnv((void**)&env, JNI_VERSION_1_8);
        
        if (getEnvResult == JNI_EDETACHED) {
            if (jvm->AttachCurrentThread((void**)&env, nullptr) != JNI_OK) {
                std::cerr << "无法附加到JVM线程" << std::endl;
                return nullptr;
            }
        } else if (getEnvResult != JNI_OK) {
            std::cerr << "无法获取JNIEnv" << std::endl;
            return nullptr;
        }
        
        // 获取HBaseBridge类
        jclass bridgeClass = env->FindClass("com/hbasegui/bridge/HBaseBridge");
        if (bridgeClass == nullptr) {
            std::cerr << "无法找到HBaseBridge类" << std::endl;
            return nullptr;
        }
        
        // 获取listTables方法
        jmethodID listTablesMethod = env->GetStaticMethodID(bridgeClass, "listTables", 
            "()Ljava/lang/String;");
        if (listTablesMethod == nullptr) {
            std::cerr << "无法找到listTables方法" << std::endl;
            env->DeleteLocalRef(bridgeClass);
            return nullptr;
        }
        
        // 调用Java方法
        jstring result = (jstring)env->CallStaticObjectMethod(bridgeClass, listTablesMethod);
        
        // 检查是否有异常发生
        if (env->ExceptionCheck()) {
            std::cerr << "Java方法执行过程中发生异常" << std::endl;
            env->ExceptionDescribe();
            env->ExceptionClear();
            env->DeleteLocalRef(bridgeClass);
            return nullptr;
        }
        
        if (result == nullptr) {
            std::cerr << "Java方法返回空" << std::endl;
            env->DeleteLocalRef(bridgeClass);
            return nullptr;
        }
        
        // 转换Java字符串到C字符串
        const char* cResult = env->GetStringUTFChars(result, nullptr);
        if (cResult == nullptr) {
            std::cerr << "无法转换Java字符串到C字符串" << std::endl;
            env->DeleteLocalRef(result);
            env->DeleteLocalRef(bridgeClass);
            return nullptr;
        }
        
        // 复制字符串，因为Java字符串会被释放
        char* copy = strdup(cResult);
        
        // 释放Java资源
        env->ReleaseStringUTFChars(result, cResult);
        env->DeleteLocalRef(result);
        env->DeleteLocalRef(bridgeClass);
        
        return copy;
    } catch (const std::exception& e) {
        std::cerr << "获取表列表过程中发生异常: " << e.what() << std::endl;
        return nullptr;
    } catch (...) {
        std::cerr << "获取表列表过程中发生未知异常" << std::endl;
        return nullptr;
    }
}

JNIEXPORT const char* JNICALL getTableData(const char* tableName, const char* startRow, const char* endRow, int limit, const char* filterPrefix) {
    try {
        // 检查参数
        if (tableName == nullptr) {
            std::cerr << "表名不能为空" << std::endl;
            return nullptr;
        }
        
        // 检查JVM状态
        if (!jvmInitialized || jvm == nullptr) {
            std::cerr << "JVM未初始化" << std::endl;
            return nullptr;
        }
        
        // 获取JNIEnv
        JNIEnv* env = nullptr;
        jint getEnvResult = jvm->GetEnv((void**)&env, JNI_VERSION_1_8);
        
        if (getEnvResult == JNI_EDETACHED) {
            if (jvm->AttachCurrentThread((void**)&env, nullptr) != JNI_OK) {
                std::cerr << "无法附加到JVM线程" << std::endl;
                return nullptr;
            }
        } else if (getEnvResult != JNI_OK) {
            std::cerr << "无法获取JNIEnv" << std::endl;
            return nullptr;
        }
        
        // 获取HBaseBridge类
        jclass bridgeClass = env->FindClass("com/hbasegui/bridge/HBaseBridge");
        if (bridgeClass == nullptr) {
            std::cerr << "无法找到HBaseBridge类" << std::endl;
            return nullptr;
        }
        
        // 获取getTableData方法
        jmethodID getTableDataMethod = env->GetStaticMethodID(bridgeClass, "getTableData", 
            "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;)Ljava/lang/String;");
        if (getTableDataMethod == nullptr) {
            std::cerr << "无法找到getTableData方法" << std::endl;
            env->DeleteLocalRef(bridgeClass);
            return nullptr;
        }
        
        // 创建Java字符串参数
        jstring tableNameStr = env->NewStringUTF(tableName);
        jstring startRowStr = startRow ? env->NewStringUTF(startRow) : nullptr;
        jstring endRowStr = endRow ? env->NewStringUTF(endRow) : nullptr;
        jstring filterPrefixStr = filterPrefix ? env->NewStringUTF(filterPrefix) : nullptr;
        
        if (tableNameStr == nullptr) {
            std::cerr << "无法创建Java字符串参数" << std::endl;
            env->DeleteLocalRef(bridgeClass);
            return nullptr;
        }
        
        // 调用Java方法
        jstring result = (jstring)env->CallStaticObjectMethod(bridgeClass, getTableDataMethod,
            tableNameStr, startRowStr, endRowStr, limit, filterPrefixStr);
        
        // 检查是否有异常发生
        if (env->ExceptionCheck()) {
            std::cerr << "Java方法执行过程中发生异常" << std::endl;
            env->ExceptionDescribe();
            env->ExceptionClear();
            env->DeleteLocalRef(tableNameStr);
            if (startRowStr) env->DeleteLocalRef(startRowStr);
            if (endRowStr) env->DeleteLocalRef(endRowStr);
            if (filterPrefixStr) env->DeleteLocalRef(filterPrefixStr);
            env->DeleteLocalRef(bridgeClass);
            return nullptr;
        }
        
        if (result == nullptr) {
            std::cerr << "Java方法返回空" << std::endl;
            env->DeleteLocalRef(tableNameStr);
            if (startRowStr) env->DeleteLocalRef(startRowStr);
            if (endRowStr) env->DeleteLocalRef(endRowStr);
            if (filterPrefixStr) env->DeleteLocalRef(filterPrefixStr);
            env->DeleteLocalRef(bridgeClass);
            return nullptr;
        }
        
        // 转换Java字符串到C字符串
        const char* cResult = env->GetStringUTFChars(result, nullptr);
        if (cResult == nullptr) {
            std::cerr << "无法转换Java字符串到C字符串" << std::endl;
            env->DeleteLocalRef(result);
            env->DeleteLocalRef(tableNameStr);
            if (startRowStr) env->DeleteLocalRef(startRowStr);
            if (endRowStr) env->DeleteLocalRef(endRowStr);
            if (filterPrefixStr) env->DeleteLocalRef(filterPrefixStr);
            env->DeleteLocalRef(bridgeClass);
            return nullptr;
        }
        
        // 复制字符串，因为Java字符串会被释放
        char* copy = strdup(cResult);
        
        // 释放Java资源
        env->ReleaseStringUTFChars(result, cResult);
        env->DeleteLocalRef(result);
        env->DeleteLocalRef(tableNameStr);
        if (startRowStr) env->DeleteLocalRef(startRowStr);
        if (endRowStr) env->DeleteLocalRef(endRowStr);
        if (filterPrefixStr) env->DeleteLocalRef(filterPrefixStr);
        env->DeleteLocalRef(bridgeClass);
        
        return copy;
    } catch (const std::exception& e) {
        std::cerr << "获取表数据过程中发生异常: " << e.what() << std::endl;
        return nullptr;
    } catch (...) {
        std::cerr << "获取表数据过程中发生未知异常" << std::endl;
        return nullptr;
    }
}

const char* executeCommand(const char* tableName, const char* command, const char* rowKey, const char* family, const char* qualifier, const char* value) {
    try {
        // 检查参数
        if (tableName == nullptr || command == nullptr) {
            std::cerr << "参数不能为空" << std::endl;
            return nullptr;
        }
        
        // 检查JVM状态
        if (!jvmInitialized || jvm == nullptr) {
            std::cerr << "JVM未初始化" << std::endl;
            return nullptr;
        }
        
        // 获取JNIEnv
        JNIEnv* env = nullptr;
        jint getEnvResult = jvm->GetEnv((void**)&env, JNI_VERSION_1_8);
        
        if (getEnvResult == JNI_EDETACHED) {
            if (jvm->AttachCurrentThread((void**)&env, nullptr) != JNI_OK) {
                std::cerr << "无法附加到JVM线程" << std::endl;
                return nullptr;
            }
        } else if (getEnvResult != JNI_OK) {
            std::cerr << "无法获取JNIEnv" << std::endl;
            return nullptr;
        }
        
        // 获取HBaseBridge类
        jclass bridgeClass = env->FindClass("com/hbasegui/bridge/HBaseBridge");
        if (bridgeClass == nullptr) {
            std::cerr << "无法找到HBaseBridge类" << std::endl;
            return nullptr;
        }
        
        // 获取executeCommand方法
        jmethodID executeCommandMethod = env->GetStaticMethodID(bridgeClass, "executeCommand", 
            "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;");
        if (executeCommandMethod == nullptr) {
            std::cerr << "无法找到executeCommand方法" << std::endl;
            env->DeleteLocalRef(bridgeClass);
            return nullptr;
        }
        
        // 创建Java字符串参数
        jstring jTableName = env->NewStringUTF(tableName);
        jstring jCommand = env->NewStringUTF(command);
        jstring jRowKey = rowKey ? env->NewStringUTF(rowKey) : nullptr;
        jstring jFamily = family ? env->NewStringUTF(family) : nullptr;
        jstring jQualifier = qualifier ? env->NewStringUTF(qualifier) : nullptr;
        jstring jValue = value ? env->NewStringUTF(value) : nullptr;
        
        if (jTableName == nullptr || jCommand == nullptr) {
            std::cerr << "无法创建Java字符串参数" << std::endl;
            if (jTableName) env->DeleteLocalRef(jTableName);
            if (jCommand) env->DeleteLocalRef(jCommand);
            if (jRowKey) env->DeleteLocalRef(jRowKey);
            if (jFamily) env->DeleteLocalRef(jFamily);
            if (jQualifier) env->DeleteLocalRef(jQualifier);
            if (jValue) env->DeleteLocalRef(jValue);
            env->DeleteLocalRef(bridgeClass);
            return nullptr;
        }
        
        // 调用Java方法
        jstring result = (jstring)env->CallStaticObjectMethod(bridgeClass, executeCommandMethod,
            jTableName, jCommand, jRowKey, jFamily, jQualifier, jValue);
        
        // 检查是否有异常发生
        if (env->ExceptionCheck()) {
            std::cerr << "Java方法执行过程中发生异常" << std::endl;
            env->ExceptionDescribe();
            env->ExceptionClear();
            env->DeleteLocalRef(jTableName);
            env->DeleteLocalRef(jCommand);
            if (jRowKey) env->DeleteLocalRef(jRowKey);
            if (jFamily) env->DeleteLocalRef(jFamily);
            if (jQualifier) env->DeleteLocalRef(jQualifier);
            if (jValue) env->DeleteLocalRef(jValue);
            env->DeleteLocalRef(bridgeClass);
            return nullptr;
        }
        
        if (result == nullptr) {
            std::cerr << "Java方法返回空" << std::endl;
            env->DeleteLocalRef(jTableName);
            env->DeleteLocalRef(jCommand);
            if (jRowKey) env->DeleteLocalRef(jRowKey);
            if (jFamily) env->DeleteLocalRef(jFamily);
            if (jQualifier) env->DeleteLocalRef(jQualifier);
            if (jValue) env->DeleteLocalRef(jValue);
            env->DeleteLocalRef(bridgeClass);
            return nullptr;
        }
        
        // 转换Java字符串到C字符串
        const char* cResult = env->GetStringUTFChars(result, nullptr);
        if (cResult == nullptr) {
            std::cerr << "无法转换Java字符串到C字符串" << std::endl;
            env->DeleteLocalRef(result);
            env->DeleteLocalRef(jTableName);
            env->DeleteLocalRef(jCommand);
            if (jRowKey) env->DeleteLocalRef(jRowKey);
            if (jFamily) env->DeleteLocalRef(jFamily);
            if (jQualifier) env->DeleteLocalRef(jQualifier);
            if (jValue) env->DeleteLocalRef(jValue);
            env->DeleteLocalRef(bridgeClass);
            return nullptr;
        }
        
        // 复制字符串，因为Java字符串会被释放
        char* copy = strdup(cResult);
        
        // 释放Java资源
        env->ReleaseStringUTFChars(result, cResult);
        env->DeleteLocalRef(result);
        env->DeleteLocalRef(jTableName);
        env->DeleteLocalRef(jCommand);
        if (jRowKey) env->DeleteLocalRef(jRowKey);
        if (jFamily) env->DeleteLocalRef(jFamily);
        if (jQualifier) env->DeleteLocalRef(jQualifier);
        if (jValue) env->DeleteLocalRef(jValue);
        env->DeleteLocalRef(bridgeClass);
        
        return copy;
    } catch (const std::exception& e) {
        std::cerr << "执行命令过程中发生异常: " << e.what() << std::endl;
        return nullptr;
    } catch (...) {
        std::cerr << "执行命令过程中发生未知异常" << std::endl;
        return nullptr;
    }
}

// 初始化JNI环境
bool initJNI() {
    if (g_jvm == nullptr) {
        std::cout << "【C++桥接】初始化JNI环境..." << std::endl;
        
        JavaVMOption options[1];
        options[0].optionString = const_cast<char*>("-Djava.class.path=../java-bridge/build/libs/java-bridge.jar");
        
        JavaVMInitArgs vm_args;
        vm_args.version = JNI_VERSION_1_8;
        vm_args.nOptions = 1;
        vm_args.options = options;
        vm_args.ignoreUnrecognized = JNI_TRUE;
        
        jint result = JNI_CreateJavaVM(&g_jvm, (void**)&g_env, &vm_args);
        if (result != JNI_OK) {
            std::cerr << "【C++桥接】创建Java虚拟机失败" << std::endl;
            return false;
        }
        
        // 加载HBaseBridge类
        g_hbaseBridgeClass = g_env->FindClass("com/hbasegui/bridge/HBaseBridge");
        if (g_hbaseBridgeClass == nullptr) {
            std::cerr << "【C++桥接】找不到HBaseBridge类" << std::endl;
            return false;
        }
        
        std::cout << "【C++桥接】JNI环境初始化成功" << std::endl;
        return true;
    }
    return true;
}

// 断开连接
JNIEXPORT void JNICALL disconnect() {
    try {
        if (jvm != nullptr) {
            JNIEnv* env;
            jint res = jvm->GetEnv((void**)&env, JNI_VERSION_1_8);
            if (res == JNI_EDETACHED) {
                jvm->AttachCurrentThread((void**)&env, nullptr);
            }
            
            if (env != nullptr) {
                // 查找HBaseBridge类
                jclass hbaseBridgeClass = env->FindClass("com/hbasegui/bridge/HBaseBridge");
                if (hbaseBridgeClass != nullptr) {
                    // 获取disconnect方法ID
                    jmethodID disconnectMethod = env->GetStaticMethodID(hbaseBridgeClass, "disconnect", "()V");
                    if (disconnectMethod != nullptr) {
                        // 调用disconnect方法
                        env->CallStaticVoidMethod(hbaseBridgeClass, disconnectMethod);
                    }
                    env->DeleteLocalRef(hbaseBridgeClass);
                }
            }
        }
    } catch (...) {
        std::cerr << "断开连接时发生异常" << std::endl;
    }
}

// 释放字符串内存
JNIEXPORT void JNICALL freeString(const char* str) {
    if (str != nullptr) {
        free((void*)str);
    }
}

} // extern "C" 