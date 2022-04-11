[Go语言101 - Go语言101（通俗版Go白皮书） (go101.org)](https://gfw.go101.org/article/101.html)

# Go

## Go命令

上面提到的三个`go`子命令（`go run`、`go build`和`go install`） 将只会输出代码语法错误。它们不会输出可能的代码逻辑错误（即警告）。 `go vet`子命令可以用来检查可能的代码逻辑错误（即警告）。

我们可以（并且应该常常）使用`go fmt`子命令来用同一种代码风格格式化Go代码。

我们可以使用`go test`子命令来运行单元和基准测试用例。

我们可以使用`go doc`子命令来（在终端中）查看Go代码库包的文档。

强烈推荐让你的Go项目支持Go模块特性来简化依赖管理。对一个支持Go模块特性的项目：

- `go mod init example.com/myproject`命令可以用来在当前目录中生成一个`go.mod`文件。 当前目录将被视为一个名为`example.com/myproject`的模块（即当前项目）的根目录。 此`go.mod`文件将被用来记录当前项目需要的依赖模块和版本信息。 我们可以手动编辑或者使用`go`子命令来修改此文件。

- `go mod tidy`命令用来通过扫描当前项目中的所有代码来添加未被记录的依赖至`go.mod`文件或从`go.mod`文件中删除不再被使用的依赖。

- `go get`命令用拉添加、升级、降级或者删除单个依赖。此命令不如`go mod tidy`命令常用。

  

  官方文档：[Command go - The Go Programming Language (google.cn)](https://golang.google.cn/cmd/go/)

## 编程入门

### 简单示例

```go
package main // 指定当前源文件所在的包名

import "math/rand" // 引入一个标准库包

const MaxRand = 16 // 声明一个有名整型常量
```

## 关键字和标识符