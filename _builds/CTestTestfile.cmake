# CMake generated Testfile for 
# Source directory: /Users/macbook/Desktop/lab07
# Build directory: /Users/macbook/Desktop/lab07/_builds
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(test1 "/Users/macbook/Desktop/lab07/_builds/test1")
set_tests_properties(test1 PROPERTIES  _BACKTRACE_TRIPLES "/Users/macbook/Desktop/lab07/CMakeLists.txt;30;add_test;/Users/macbook/Desktop/lab07/CMakeLists.txt;0;")
subdirs("third-party/gtest")
