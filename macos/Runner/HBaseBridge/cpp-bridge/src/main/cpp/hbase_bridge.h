#ifndef HBASE_BRIDGE_H
#define HBASE_BRIDGE_H

#include <jni.h>

#ifdef __cplusplus
extern "C" {
#endif

// 连接HBase
bool connect(const char* zkQuorum, const char* zkNode);

// 断开连接
void disconnect();

// 获取表列表
const char* listTables();

// 获取表数据
const char* getTableData(const char* tableName, const char* startRow, const char* endRow, int limit, const char* filterPrefix);

// 执行命令
const char* executeCommand(const char* tableName, const char* command, const char* rowKey, const char* family, const char* qualifier, const char* value);

// 释放字符串内存
void freeString(const char* str);

#ifdef __cplusplus
}
#endif

#endif // HBASE_BRIDGE_H 