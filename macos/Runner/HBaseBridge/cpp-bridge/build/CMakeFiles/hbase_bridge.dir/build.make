# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.30

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Disable VCS-based implicit rules.
% : %,v

# Disable VCS-based implicit rules.
% : RCS/%

# Disable VCS-based implicit rules.
% : RCS/%,v

# Disable VCS-based implicit rules.
% : SCCS/s.%

# Disable VCS-based implicit rules.
% : s.%

.SUFFIXES: .hpux_make_needs_suffix_list

# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/local/Cellar/cmake/3.30.2/bin/cmake

# The command to remove a file.
RM = /usr/local/Cellar/cmake/3.30.2/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/HBaseBridge/cpp-bridge

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/HBaseBridge/cpp-bridge/build

# Include any dependencies generated for this target.
include CMakeFiles/hbase_bridge.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include CMakeFiles/hbase_bridge.dir/compiler_depend.make

# Include the progress variables for this target.
include CMakeFiles/hbase_bridge.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/hbase_bridge.dir/flags.make

CMakeFiles/hbase_bridge.dir/src/main/cpp/hbase_bridge.cpp.o: CMakeFiles/hbase_bridge.dir/flags.make
CMakeFiles/hbase_bridge.dir/src/main/cpp/hbase_bridge.cpp.o: /Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/HBaseBridge/cpp-bridge/src/main/cpp/hbase_bridge.cpp
CMakeFiles/hbase_bridge.dir/src/main/cpp/hbase_bridge.cpp.o: CMakeFiles/hbase_bridge.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/HBaseBridge/cpp-bridge/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object CMakeFiles/hbase_bridge.dir/src/main/cpp/hbase_bridge.cpp.o"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/hbase_bridge.dir/src/main/cpp/hbase_bridge.cpp.o -MF CMakeFiles/hbase_bridge.dir/src/main/cpp/hbase_bridge.cpp.o.d -o CMakeFiles/hbase_bridge.dir/src/main/cpp/hbase_bridge.cpp.o -c /Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/HBaseBridge/cpp-bridge/src/main/cpp/hbase_bridge.cpp

CMakeFiles/hbase_bridge.dir/src/main/cpp/hbase_bridge.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/hbase_bridge.dir/src/main/cpp/hbase_bridge.cpp.i"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/HBaseBridge/cpp-bridge/src/main/cpp/hbase_bridge.cpp > CMakeFiles/hbase_bridge.dir/src/main/cpp/hbase_bridge.cpp.i

CMakeFiles/hbase_bridge.dir/src/main/cpp/hbase_bridge.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/hbase_bridge.dir/src/main/cpp/hbase_bridge.cpp.s"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/HBaseBridge/cpp-bridge/src/main/cpp/hbase_bridge.cpp -o CMakeFiles/hbase_bridge.dir/src/main/cpp/hbase_bridge.cpp.s

# Object files for target hbase_bridge
hbase_bridge_OBJECTS = \
"CMakeFiles/hbase_bridge.dir/src/main/cpp/hbase_bridge.cpp.o"

# External object files for target hbase_bridge
hbase_bridge_EXTERNAL_OBJECTS =

hbase_bridge.dylib: CMakeFiles/hbase_bridge.dir/src/main/cpp/hbase_bridge.cpp.o
hbase_bridge.dylib: CMakeFiles/hbase_bridge.dir/build.make
hbase_bridge.dylib: /Library/Java/JavaVirtualMachines/jdk1.8.0_301.jdk/Contents/Home/jre/lib/libjawt.dylib
hbase_bridge.dylib: /Library/Java/JavaVirtualMachines/jdk1.8.0_301.jdk/Contents/Home/jre/lib/server/libjvm.dylib
hbase_bridge.dylib: CMakeFiles/hbase_bridge.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --bold --progress-dir=/Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/HBaseBridge/cpp-bridge/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX shared library hbase_bridge.dylib"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/hbase_bridge.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/hbase_bridge.dir/build: hbase_bridge.dylib
.PHONY : CMakeFiles/hbase_bridge.dir/build

CMakeFiles/hbase_bridge.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/hbase_bridge.dir/cmake_clean.cmake
.PHONY : CMakeFiles/hbase_bridge.dir/clean

CMakeFiles/hbase_bridge.dir/depend:
	cd /Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/HBaseBridge/cpp-bridge/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/HBaseBridge/cpp-bridge /Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/HBaseBridge/cpp-bridge /Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/HBaseBridge/cpp-bridge/build /Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/HBaseBridge/cpp-bridge/build /Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/HBaseBridge/cpp-bridge/build/CMakeFiles/hbase_bridge.dir/DependInfo.cmake "--color=$(COLOR)"
.PHONY : CMakeFiles/hbase_bridge.dir/depend

