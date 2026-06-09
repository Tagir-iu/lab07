# Отчет по лабораторной работе №7

**Студент:** Tagir-iu  
**Тема:** Система управления зависимостями Hunter (попытка внедрения)

---

## 1. Цель работы

Изучить систему управления зависимостями **Hunter** для C++ проектов, научиться подключать сторонние библиотеки (GTest) и создавать собственные пакеты.

---

## 2. Задание

1. Настроить интеграцию Hunter в CMake проект
2. Подключить библиотеку GTest через Hunter
3. Написать модульные тесты для классов `Account` и `Transaction`
4. Настроить CI через GitHub Actions
5. Создать пакеты (DEB, RPM, TGZ, ZIP) при помечении коммита тэгом

---

## 3. Выполнение работы

### 3.1. Структура проекта
```
lab07/
├── banking/
│ ├── Account.h
│ ├── Account.cpp
│ ├── Transaction.h
│ ├── Transaction.cpp
│ └── CMakeLists.txt
├── tests/
│ ├── test_account.cpp
│ └── test_transaction.cpp
├── .github/workflows/
│ └── linux.yml
├── CMakeLists.txt
├── CPackConfig.cmake
├── DESCRIPTION
├── LICENSE
├── ChangeLog.md
└── README.md
```


### 3.2. Попытка интеграции Hunter

Была предпринята попытка настроить Hunter в `CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.4)

include("cmake/HunterGate.cmake")
HunterGate(
    URL "https://github.com/cpp-pm/hunter/archive/v0.23.13.tar.gz"
    SHA1 "ef7d6ac5a4ba88307b2bea3e6ed7206c69f542e8"
)

project(lab07)
```
### 3.3. Возникшие проблемы

При попытке использования Hunter возникли следующие ошибки:
```
    Ошибка скачивания GTest — Hunter не мог скачать GTest из-за проблем с SHA1
    Ошибка компиляции GTest — сборка GTest падала с -Werror (предупреждения трактовались как ошибки)
    Ошибка hunter_error_page — внутренняя ошибка Hunter при скачивании пакетов
```
### 3.4 Альтернативное решение 
В связи с невозможностью использовать Hunter (проблемы с сетью и совместимостью), было принято решение использовать классический GTest через add_subdirectory:
```
if(BUILD_TESTS)
    enable_testing()
    
    add_subdirectory(third-party/gtest)
    
    add_executable(check tests/test_account.cpp tests/test_transaction.cpp)
    target_link_libraries(check banking gtest_main)
    target_include_directories(check PRIVATE banking)
    
    add_test(NAME check COMMAND check)
endif()
```

### 3.5 Класс Account
```
class Account {
private:
    std::string id;
    double balance;
public:
    Account(const std::string& id, double initialBalance = 0.0);
    void deposit(double amount);
    bool withdraw(double amount);
    double getBalance() const;
    std::string getId() const;
};
```


### 3.6 Класс Transaction
```
class Transaction {
private:
    std::string fromId;
    std::string toId;
    double amount;
    bool completed;
public:
    Transaction(const std::string& from, const std::string& to, double amount);
    bool execute(Account& from, Account& to);
    bool isCompleted() const;
    double getAmount() const;
};
```

### 3.7 Добавляем GTest как git submodule:
```
git submodule add https://github.com/google/googletest third-party/gtest
cd third-party/gtest && git checkout release-1.12.1
```

### 3.8 Проверка и анализ на модульных тестах
введем классификацию тестов

```
name: Linux CI (gcc & clang)

on:
  push:
    branches: [ main, master ]
    tags: [ 'v*' ]
  pull_request:
    branches: [ main, master ]

jobs:
  build:
    runs-on: ubuntu-22.04
    strategy:
      matrix:
        compiler: [gcc, clang]
    env:
      CC: ${{ matrix.compiler == 'gcc' && 'gcc' || 'clang' }}
      CXX: ${{ matrix.compiler == 'gcc' && 'g++' || 'clang++' }}

    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive
          fetch-depth: 0

      - name: Initialize Submodules
        run: git submodule update --init --recursive

      - name: Install GTest (Logs for demo)
        run: |
          sudo apt-get update
          sudo apt-get install -y googletest libgtest-dev

      - name: Install dependencies
        run: |
          sudo apt-get install -y cmake build-essential rpm

      - name: Configure
        run: cmake -H. -B_build -DBUILD_TESTS=ON

      - name: Build
        run: cmake --build _build

      - name: Test
        run: ctest --test-dir _build --output-on-failure

      - name: Create packages
        if: startsWith(github.ref, 'refs/tags/')
        run: |
          cd _build
          cpack -G DEB
          cpack -G RPM
          cpack -G TGZ
          cpack -G ZIP

      - name: Upload Release
        if: startsWith(github.ref, 'refs/tags/')
        uses: softprops/action-gh-release@v1
        with:
          files: _build/*.deb _build/*.rpm _build/*.tar.gz _build/*.zip
```

### 4.0 Проверка результатов
вывод:
```
[==========] Running 7 tests from 2 test suites.
[----------] 3 tests from AccountTest
[ RUN      ] AccountTest.ConstructorInitializesBalance
[       OK ] AccountTest.ConstructorInitializesBalance
[ RUN      ] AccountTest.DepositIncreasesBalance
[       OK ] AccountTest.DepositIncreasesBalance
[ RUN      ] AccountTest.WithdrawDecreasesBalance
[       OK ] AccountTest.WithdrawDecreasesBalance
[----------] 3 tests from AccountTest

[----------] 4 tests from TransactionTest
[ RUN      ] TransactionTest.ExecuteTransfersMoney
[       OK ] TransactionTest.ExecuteTransfersMoney
[ RUN      ] TransactionTest.ExecuteFailsIfInsufficientFunds
[       OK ] TransactionTest.ExecuteFailsIfInsufficientFunds
[ RUN      ] TransactionTest.ExecuteFailsIfAlreadyCompleted
[       OK ] TransactionTest.ExecuteFailsIfAlreadyCompleted
[ RUN      ] TransactionTest.ExecuteFailsWithWrongAccounts
[       OK ] TransactionTest.ExecuteFailsWithWrongAccounts
[----------] 4 tests from TransactionTest

[==========] 7 tests from 2 test suites ran.
[  PASSED  ] 7 tests.
```

## Вывод
К сожалению в силу некоторых особенностей системы мне не удалось прилинковать
Hunter к моей сборке, от чего использовал стандарную связку GTest через submodule
