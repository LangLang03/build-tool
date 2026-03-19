# Java 项目示例

本文档展示如何使用 build-tool 构建一个完整的 Java 项目。

---

## 目录

- [项目结构](#项目结构)
- [配置文件](#配置文件)
- [源代码](#源代码)
- [构建命令](#构建命令)
- [高级配置](#高级配置)

---

## 项目结构

```
my-java-project/
├── build.yaml              # 构建配置
├── src/
│   └── main/
│       └── java/
│           └── com/
│               └── example/
│                   ├── Main.java
│                   ├── Calculator.java
│                   └── Utils.java
├── src/
│   └── test/
│       └── java/
│           └── com/
│               └── example/
│                   └── CalculatorTest.java
├── src/
│   └── main/
│       └── resources/
│           └── config.properties
├── lib/                    # 依赖库
│   └── gson-2.10.1.jar
├── scripts/
│   ├── build.sh
│   ├── test.sh
│   └── run.sh
└── README.md
```

---

## 配置文件

### build.yaml

```yaml
project:
  name: my-java-app
  version: 1.0.0
  description: 示例 Java 应用程序

directories:
  source: src/main/java
  build: target/classes
  resources: src/main/resources
  test: src/test/java

plugins:
  - java

java:
  jar_output: ${project.name}-${project.version}.jar
  main_class: com.example.Main
  source: 17
  target: 17
  opts: -Xlint:all -encoding UTF-8
  run_opts: -Xmx512m
  classpath: lib/*

targets:
  build: scripts/build.sh
  test: scripts/test.sh
  run: scripts/run.sh
  package: scripts/package.sh

hooks:
  pre_build: scripts/hooks/pre_build.sh
  post_build: scripts/hooks/post_build.sh
```

---

## 源代码

### Main.java

```java
package com.example;

public class Main {
    public static void main(String[] args) {
        System.out.println("Hello, Build Tool!");
        
        Calculator calc = new Calculator();
        int result = calc.add(10, 20);
        System.out.println("10 + 20 = " + result);
        
        Utils.printInfo();
    }
}
```

### Calculator.java

```java
package com.example;

public class Calculator {
    public int add(int a, int b) {
        return a + b;
    }
    
    public int subtract(int a, int b) {
        return a - b;
    }
    
    public int multiply(int a, int b) {
        return a * b;
    }
    
    public double divide(int a, int b) {
        if (b == 0) {
            throw new IllegalArgumentException("除数不能为零");
        }
        return (double) a / b;
    }
}
```

### Utils.java

```java
package com.example;

public class Utils {
    public static void printInfo() {
        System.out.println("项目: my-java-app");
        System.out.println("版本: 1.0.0");
    }
}
```

---

## 构建命令

### 查看可用目标

```bash
build list
```

输出：

```
Available targets:
build - 编译 Java 源码
clean - 清理构建产物
jar - 创建 JAR 文件
run - 运行主类
test - 运行测试
```

### 编译项目

```bash
build build
```

### 运行测试

```bash
build test
```

### 打包 JAR

```bash
build jar
```

### 运行程序

```bash
build run
```

### 清理

```bash
build clean
```

---

## 高级配置

### 多环境配置

创建不同环境的配置文件：

```bash
# 开发环境
build -c build.dev.yaml build

# 生产环境
build -c build.prod.yaml build
```

### CI/CD 集成

```yaml
# .github/workflows/build.yml
name: Build

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
      
      - name: Build
        run: ./build build
      
      - name: Test
        run: ./build test
      
      - name: Package
        run: ./build jar
```

---

## 下一步

- [自定义目标示例](custom-targets.md) - 自定义目标示例
- [配置详解](../user-guide/configuration.md) - 更多配置选项
