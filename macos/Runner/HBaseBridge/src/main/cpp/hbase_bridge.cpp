#include <jni.h>
#include <string>
#include <vector>
#include <map>

static JavaVM* jvm = nullptr;
static jobject bridgeInstance = nullptr;

extern "C" {

bool connect(const char* zkQuorum, const char* zkNode) {
    JNIEnv* env;
    jvm->AttachCurrentThread((void**)&env, nullptr);

    jclass bridgeClass = env->FindClass("com/hbasegui/bridge/HBaseBridge");
    jmethodID connectMethod = env->GetStaticMethodID(bridgeClass, "connect", "(Ljava/lang/String;Ljava/lang/String;)Z");

    jstring jZkQuorum = env->NewStringUTF(zkQuorum);
    jstring jZkNode = env->NewStringUTF(zkNode);

    jboolean result = env->CallStaticBooleanMethod(bridgeClass, connectMethod, jZkQuorum, jZkNode);

    env->DeleteLocalRef(jZkQuorum);
    env->DeleteLocalRef(jZkNode);
    env->DeleteLocalRef(bridgeClass);

    return result;
}

const char* listTables() {
    JNIEnv* env;
    jvm->AttachCurrentThread((void**)&env, nullptr);

    jclass bridgeClass = env->FindClass("com/hbasegui/bridge/HBaseBridge");
    jmethodID listTablesMethod = env->GetStaticMethodID(bridgeClass, "listTables", "()Ljava/util/List;");

    jobject resultList = env->CallStaticObjectMethod(bridgeClass, listTablesMethod);

    // Convert Java List to JSON string
    jclass jsonClass = env->FindClass("org/json/JSONArray");
    jmethodID jsonConstructor = env->GetMethodID(jsonClass, "<init>", "(Ljava/util/Collection;)V");
    jobject jsonArray = env->NewObject(jsonClass, jsonConstructor, resultList);
    jmethodID toStringMethod = env->GetMethodID(jsonClass, "toString", "()Ljava/lang/String;");
    jstring jsonString = (jstring)env->CallObjectMethod(jsonArray, toStringMethod);

    const char* result = env->GetStringUTFChars(jsonString, nullptr);

    env->DeleteLocalRef(bridgeClass);
    env->DeleteLocalRef(resultList);
    env->DeleteLocalRef(jsonClass);
    env->DeleteLocalRef(jsonArray);
    env->DeleteLocalRef(jsonString);

    return result;
}

const char* getTableData(const char* tableName, const char* startRow, const char* endRow, int limit, const char* filterPrefix) {
    JNIEnv* env;
    jvm->AttachCurrentThread((void**)&env, nullptr);

    jclass bridgeClass = env->FindClass("com/hbasegui/bridge/HBaseBridge");
    jmethodID getDataMethod = env->GetStaticMethodID(bridgeClass, "getTableData", 
        "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;)Ljava/util/List;");

    jstring jTableName = env->NewStringUTF(tableName);
    jstring jStartRow = env->NewStringUTF(startRow);
    jstring jEndRow = env->NewStringUTF(endRow);
    jstring jFilterPrefix = env->NewStringUTF(filterPrefix);

    jobject resultList = env->CallStaticObjectMethod(bridgeClass, getDataMethod, 
        jTableName, jStartRow, jEndRow, limit, jFilterPrefix);

    // Convert Java List to JSON string
    jclass jsonClass = env->FindClass("org/json/JSONArray");
    jmethodID jsonConstructor = env->GetMethodID(jsonClass, "<init>", "(Ljava/util/Collection;)V");
    jobject jsonArray = env->NewObject(jsonClass, jsonConstructor, resultList);
    jmethodID toStringMethod = env->GetMethodID(jsonClass, "toString", "()Ljava/lang/String;");
    jstring jsonString = (jstring)env->CallObjectMethod(jsonArray, toStringMethod);

    const char* result = env->GetStringUTFChars(jsonString, nullptr);

    env->DeleteLocalRef(jTableName);
    env->DeleteLocalRef(jStartRow);
    env->DeleteLocalRef(jEndRow);
    env->DeleteLocalRef(jFilterPrefix);
    env->DeleteLocalRef(bridgeClass);
    env->DeleteLocalRef(resultList);
    env->DeleteLocalRef(jsonClass);
    env->DeleteLocalRef(jsonArray);
    env->DeleteLocalRef(jsonString);

    return result;
}

bool executeCommand(const char* tableName, const char* command) {
    JNIEnv* env;
    jvm->AttachCurrentThread((void**)&env, nullptr);

    jclass bridgeClass = env->FindClass("com/hbasegui/bridge/HBaseBridge");
    jmethodID executeMethod = env->GetStaticMethodID(bridgeClass, "executeCommand", 
        "(Ljava/lang/String;Ljava/lang/String;)Z");

    jstring jTableName = env->NewStringUTF(tableName);
    jstring jCommand = env->NewStringUTF(command);

    jboolean result = env->CallStaticBooleanMethod(bridgeClass, executeMethod, jTableName, jCommand);

    env->DeleteLocalRef(jTableName);
    env->DeleteLocalRef(jCommand);
    env->DeleteLocalRef(bridgeClass);

    return result;
}

} 