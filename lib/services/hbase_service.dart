import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'dart:convert';
import 'dart:io' show Platform, Directory, pid;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:isolate';
import 'package:path/path.dart' as path;

// 定义JNI函数类型
typedef InitJVMNative = ffi.Bool Function();
typedef InitJVM = bool Function();

typedef ConnectNative = ffi.Bool Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
typedef Connect = bool Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef GetTablesNative = ffi.Pointer<Utf8> Function();
typedef GetTables = ffi.Pointer<Utf8> Function();

typedef GetTableDataNative = ffi.Pointer<Utf8> Function(
  ffi.Pointer<Utf8> tableName,
  ffi.Pointer<Utf8> startRow,
  ffi.Pointer<Utf8> endRow,
  ffi.Int32 limit,
  ffi.Pointer<Utf8> filterPrefix,
);
typedef GetTableData = ffi.Pointer<Utf8> Function(
  ffi.Pointer<Utf8> tableName,
  ffi.Pointer<Utf8> startRow,
  ffi.Pointer<Utf8> endRow,
  int limit,
  ffi.Pointer<Utf8> filterPrefix,
);

typedef ExecuteCommandNative = ffi.Bool Function(
  ffi.Pointer<Utf8> tableName,
  ffi.Pointer<Utf8> command,
);
typedef ExecuteCommand = bool Function(
  ffi.Pointer<Utf8> tableName,
  ffi.Pointer<Utf8> command,
);

typedef DisconnectNative = ffi.Void Function();
typedef Disconnect = void Function();

typedef FreeStringNative = ffi.Void Function(ffi.Pointer<Utf8>);
typedef FreeString = void Function(ffi.Pointer<Utf8>);

class HBaseService extends GetxService {
  static final HBaseService _instance = HBaseService._internal();
  factory HBaseService() => _instance;
  HBaseService._internal();

  ffi.DynamicLibrary? _lib;
  Connect? _connect;
  Disconnect? _disconnect;
  FreeString? _freeString;
  GetTables? _listTables;
  GetTableData? _getTableData;
  ExecuteCommand? _executeCommand;

  final isConnected = false.obs;
  String? zkQuorum;
  String? zkNode;

  bool _isInitialized = false;
  bool _isLibraryLoaded = false;
  
  // 模拟模式标志
  final isMockMode = true.obs;
  
  // 强制使用模拟模式
  final _forceMockMode = false;

  @override
  void onInit() {
    super.onInit();
    // 尝试加载库，但不影响默认的模拟模式
    if (!_forceMockMode) {
      _tryLoadLibrary();
    } else {
      print('强制模拟模式已启用，跳过原生库加载');
    }
  }

  bool _tryLoadLibrary() {
    // 如果已经加载成功，直接返回
    if (_isLibraryLoaded) {
      print('库已加载，不需要重新加载');
      return true;
    }
    
    print('尝试加载原生库...');
    try {
      // 尝试在不同位置加载库
      _lib = null; // 重置
      
      // 构建可能的库路径
      String? libraryPath;
      
      if (Platform.isMacOS) {
        // macOS平台的路径 - 优先尝试应用包内路径
        final paths = [
          // 1. 应用沙箱内的路径（沙箱环境下最可能成功的路径）
          '/Users/hexufeng/Library/Containers/com.example.hbaseguiv2/Data/macos/Runner/Frameworks/libhbase_bridge.dylib',
          // 2. 应用包内的Frameworks目录
          '${Directory.current.path}/build/macos/Build/Products/Debug/hbaseguiv2.app/Contents/Frameworks/libhbase_bridge.dylib',
          // 3. 相对路径
          '../Frameworks/libhbase_bridge.dylib',
          // 4. 开发环境中的路径
          '/Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/Frameworks/libhbase_bridge.dylib', 
          // 5. 开发环境中的相对路径
          '${Directory.current.path}/macos/Runner/Frameworks/libhbase_bridge.dylib',
          // 6. Xcode构建目录
          '/Users/hexufeng/Learn/MacAPP/hbaseguiv2/build/macos/Build/Products/Debug/hbaseguiv2.app/Contents/Frameworks/libhbase_bridge.dylib',
        ];
        
        print('当前工作目录: ${Directory.current.path}');
        
        for (final path in paths) {
          try {
            print('尝试加载库: $path');
            final lib = ffi.DynamicLibrary.open(path);
            _lib = lib;
            libraryPath = path;
            print('成功从路径加载库: $path');
            break;
          } catch (e) {
            // 提取错误消息的核心部分，避免过长日志
            final errorMsg = e.toString().split('\n').first;
            print('从路径加载库失败 $path: $errorMsg');
          }
        }
      } else if (Platform.isWindows) {
        // Windows平台的路径
        final paths = [
          'hbase_bridge.dll',
          '${Directory.current.path}\\windows\\runner\\hbase_bridge.dll',
        ];
        
        for (final path in paths) {
          try {
            print('尝试加载库: $path');
            final lib = ffi.DynamicLibrary.open(path);
            _lib = lib;
            libraryPath = path;
            print('成功从路径加载库: $path');
            break;
          } catch (e) {
            print('从路径加载库失败 $path: $e');
          }
        }
      } else if (Platform.isLinux) {
        // Linux平台的路径
        final paths = [
          'libhbase_bridge.so',
          '${Directory.current.path}/linux/bundle/lib/libhbase_bridge.so',
        ];
        
        for (final path in paths) {
          try {
            print('尝试加载库: $path');
            final lib = ffi.DynamicLibrary.open(path);
            _lib = lib;
            libraryPath = path;
            print('成功从路径加载库: $path');
            break;
          } catch (e) {
            print('从路径加载库失败 $path: $e');
          }
        }
      }
      
      if (_lib == null) {
        print('无法在任何路径找到库，将使用模拟模式');
        return false;
      }

      print('库加载成功，尝试获取函数引用');
      
      // 获取函数引用
      try {
        final lib = _lib!;
        _connect = lib.lookupFunction<ConnectNative, Connect>('connect');
        _disconnect = lib.lookupFunction<DisconnectNative, Disconnect>('disconnect');
        _listTables = lib.lookupFunction<GetTablesNative, GetTables>('listTables');
        _getTableData = lib.lookupFunction<GetTableDataNative, GetTableData>('getTableData');
        _executeCommand = lib.lookupFunction<ExecuteCommandNative, ExecuteCommand>('executeCommand');
        _freeString = lib.lookupFunction<FreeStringNative, FreeString>('freeString');
        
        // 初始化JVM
        if (_connect != null) {
          print('【JVM初始化】开始调用connect方法...');
          print('【JVM初始化】当前JAVA_HOME: ${Platform.environment['JAVA_HOME']}');
          print('【JVM初始化】当前PATH: ${Platform.environment['PATH']}');
          print('【JVM初始化】当前工作目录: ${Directory.current.path}');
          print('【JVM初始化】当前进程ID: ${pid}');
          print('【JVM初始化】当前线程ID: ${identityHashCode(this)}');
          print('【JVM初始化】当前操作系统: ${Platform.operatingSystem}');
          print('【JVM初始化】当前操作系统版本: ${Platform.operatingSystemVersion}');
          
          // 创建空字符串指针
          final emptyStr = ''.toNativeUtf8();
          bool jvmInitResult = _connect!(emptyStr, emptyStr);
          malloc.free(emptyStr);
          print('【JVM初始化】结果: $jvmInitResult');
          
          if (!jvmInitResult) {
            print('【JVM初始化】失败，将使用模拟模式');
            _lib = null;
            return false;
          } else {
            print('【JVM初始化】成功，继续执行');
          }
        } else {
          print('【JVM初始化】找不到connect方法，将使用模拟模式');
          _lib = null;
          return false;
        }
        
        _isLibraryLoaded = true;
        isMockMode.value = false; // 成功加载后，切换到真实模式
        print('原生库加载成功，设置为真实模式');
        return true;
      } catch (e, stackTrace) {
        print('获取函数引用失败: $e');
        print('错误堆栈: $stackTrace');
        _lib = null;
        return false;
      }
    } catch (e, stackTrace) {
      print('加载原生库失败: $e');
      print('错误堆栈: $stackTrace');
      isMockMode.value = true; // 保持模拟模式
      _isLibraryLoaded = false;
      return false;
    }
  }

  // Native方法是否可用
  bool get _isNativeMethodsAvailable {
    return _isLibraryLoaded &&
           _connect != null &&
           _disconnect != null;
  }
  
  Future<bool> connect(String quorum, String node) async {
    try {
      print('【连接调试】开始执行connect方法，线程ID: ${identityHashCode(this)}');
      print('【连接调试】连接参数：zkQuorum=$quorum, zkNode=$node');
      // 在使用参数前验证
      if (quorum.isEmpty || node.isEmpty) {
        print('【错误】连接参数无效：zkQuorum或zkNode为空');
        return false;
      }

      print('【连接调试】进入安全执行区域...');
      isConnected.value = false;
      zkQuorum = quorum;
      zkNode = node;

      if (isMockMode.value) {
        // 模拟模式下，直接返回成功
        isConnected.value = true;
        return true;
      }

      if (!_isNativeMethodsAvailable || _connect == null) {
        print('【错误】Native方法不可用');
        return false;
      }

      final quorumPtr = quorum.toNativeUtf8();
      final nodePtr = node.toNativeUtf8();
      
      try {
        final result = _connect!(quorumPtr, nodePtr);
        isConnected.value = result;
        return result;
      } finally {
        malloc.free(quorumPtr);
        malloc.free(nodePtr);
      }
    } catch (e, stackTrace) {
      print('【错误】连接失败: $e');
      print('【错误】堆栈: $stackTrace');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      if (!_isNativeMethodsAvailable || _disconnect == null) {
        print('【错误】Native方法不可用');
        return;
      }

      _disconnect!();
      isConnected.value = false;
      zkQuorum = null;
      zkNode = null;
    } catch (e, stackTrace) {
      print('【错误】断开连接失败: $e');
      print('【错误】堆栈: $stackTrace');
    }
  }

  Future<List<String>> getTables() async {
    try {
      if (isMockMode.value) {
        // 模拟模式下返回测试数据
        return ['test_table', 'user_table', 'data_table'];
      }

      if (!_isNativeMethodsAvailable || _listTables == null || _freeString == null) {
        print('【错误】Native方法不可用');
        return [];
      }

      final resultPtr = _listTables!();
      if (resultPtr == null) {
        print('【错误】获取表列表失败：返回空指针');
        return [];
      }

      final result = resultPtr.toDartString();
      _freeString!(resultPtr);

      final List<dynamic> tables = jsonDecode(result);
      return tables.cast<String>();
    } catch (e, stackTrace) {
      print('【错误】获取表列表失败: $e');
      print('【错误】堆栈: $stackTrace');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTableData(
    String tableName, {
    String startRow = '',
    String endRow = '',
    int limit = 100,
    String filterPrefix = '',
  }) async {
    try {
      if (isMockMode.value) {
        // 模拟模式下返回测试数据
        return [
          {'row': 'row1', 'cf:col1': 'value1', 'cf:col2': 'value2'},
          {'row': 'row2', 'cf:col1': 'value3', 'cf:col2': 'value4'},
        ];
      }

      if (!_isNativeMethodsAvailable || _getTableData == null || _freeString == null) {
        print('【错误】Native方法不可用');
        return [];
      }

      final tableNamePtr = tableName.toNativeUtf8();
      final startRowPtr = startRow.toNativeUtf8();
      final endRowPtr = endRow.toNativeUtf8();
      final filterPrefixPtr = filterPrefix.toNativeUtf8();

      try {
        final resultPtr = _getTableData!(
          tableNamePtr,
          startRowPtr,
          endRowPtr,
          limit,
          filterPrefixPtr,
        );

        if (resultPtr == null) {
          print('【错误】获取表数据失败：返回空指针');
          return [];
        }

        final result = resultPtr.toDartString();
        _freeString!(resultPtr);

        final List<dynamic> rows = jsonDecode(result);
        return rows.cast<Map<String, dynamic>>();
      } finally {
        malloc.free(tableNamePtr);
        malloc.free(startRowPtr);
        malloc.free(endRowPtr);
        malloc.free(filterPrefixPtr);
      }
    } catch (e, stackTrace) {
      print('【错误】获取表数据失败: $e');
      print('【错误】堆栈: $stackTrace');
      return [];
    }
  }

  Future<bool> executeCommand(String tableName, String command) async {
    try {
      if (isMockMode.value) {
        // 模拟模式下直接返回成功
        return true;
      }

      if (!_isNativeMethodsAvailable || _executeCommand == null) {
        print('【错误】Native方法不可用');
        return false;
      }

      final tableNamePtr = tableName.toNativeUtf8();
      final commandPtr = command.toNativeUtf8();

      try {
        return _executeCommand!(tableNamePtr, commandPtr);
      } finally {
        malloc.free(tableNamePtr);
        malloc.free(commandPtr);
      }
    } catch (e, stackTrace) {
      print('【错误】执行命令失败: $e');
      print('【错误】堆栈: $stackTrace');
      return false;
    }
  }
} 