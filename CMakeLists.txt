cmake_minimum_required(VERSION 3.5)

project(lab07)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Собираем основную библиотеку из папки banking (раз у тебя там Account)
add_library(banking_lib STATIC banking/Account.cpp banking/Transaction.cpp)

# Даем библиотеке доступ к ее же заголовочным файлам
target_include_directories(banking_lib PUBLIC banking)

# Подключаем GTest
add_subdirectory(third-party/gtest)

option(BUILD_TESTS "Build tests" ON)

if(BUILD_TESTS)
  enable_testing()
  
  add_executable(test1 tests/test_account.cpp tests/test_transaction.cpp)
  
  # Линкуем тест с библиотекой
  target_link_libraries(test1 banking_lib gtest_main)
  
  # ВАЖНО: Указываем тесту, где искать заголовочные файлы
  target_include_directories(test1 PRIVATE banking)
  
  add_test(NAME test1 COMMAND test1)
endif()