### 导读

JSON 是一种常见的数据格式，但 zsh 并没有原生的方法处理 JSON 数据，好在有一个功能强大易用的 [jq](https://stedolan.github.io/jq/) 命令行工具。本文主要讲 jq 命令的方法，虽然网上有很多相关资料，但比较零散不成系统，用于学习尚可，但作为手册查询的话并不方便。本文会将所有相关资料组织起来，便于学习和查询。本文使用的 jq 版本为 1.5。

需要注意的是如果要频繁处理 JSON 数据，用 zsh 并不合适，因为频繁调用 jq 命令会带来巨大的进程启动开销，而且 zsh 和 jq 之间的衔接也不是很自然，总体上并不如 Python 等语言好用。

### 读取字段

示例文件 test.json：

```
{
  "int": 100,
  "str": "hello",
  "array": [
    "array_element1",
    "array_element2",
    "array_element3"
  ],
  "hashtable": {
    "k1": "v1",
    "k2": "v2",
    "k3": "v3",
    "k4": [
      "aaa",
      "bbb",
      "ccc"
    ]
  }
}
```

用法示例：

```
# 读取一个整数
% cat test.json | jq .int
100

# 或者直接加文件名
# 我为了方便修改统一使用 cat，实际使用时建议加文件名，可以少启动一个进程
% jq .int test.json
100

# 读取一个字符串，输出带引号
% cat test.json | jq .str
"hello"

# 读取一个字符串，输出不带引号，但注意字段不存在的情况
% cat test.json | jq -r .str
hello

# 读取不存在的字段
% cat test.json | jq .strr
null

# 读取一个数组
% cat test.json | jq .array
[
  "array_element1",
  "array_element2",
  "array_element3"
]

# 读取数组第一个元素，也可以加 -r 去掉引号，不赘述
% cat test.json | jq '.array[0]'
"array_element1"

# 可以用 noglob 去掉 .array[0] 两边的引号，alias 下可以方便很多
% cat test.json | noglob jq .array[0]
"array_element1"

# 读取一个哈希表
% cat test.json | jq .hashtable
{
  "k1": "v1",
  "k2": "v2",
  "k3": "v3",
  "k4": [
    "aaa",
    "bbb",
    "ccc"
  ]
}

# 读取哈希表中的一个元素
% cat test.json | jq .hashtable.k2
"v2"

# 也可以这样，中某些复杂场景分开写比较方便，类似管道
% cat test.json | jq '.hashtable | .k2'
"v2"

# 读取哈希表中的数组元素
% cat test.json | jq '.hashtable.k4[1]'
"bbb"

# 格式化 JSON 数据
% cat test.json | jq
{
  "int": 100,
  "str": "hello",
  "array": [
    "array_element1",
    "array_element2",
    "array_element3"
  ],
  "hashtable": {
    "k1": "v1",
    "k2": "v2",
    "k3": "v3",
    "k4": [
      "aaa",
      "bbb",
      "ccc"
    ]
  }
}
```

### 数组相关操作

实例文件 array.json：

```
[
  [
    "aaa",
    "bbb",
    "ccc"
  ],
  [
    "ddd",
    "eee",
    "fff"
  ]
]
```

### 数组读取

```
# 读取数组长度
% cat array.json | jq length
2

# 读取第一个元素
% cat array.json | jq '.[0]'
[
  "aaa",
  "bbb",
  "ccc"
]

# 读取第一个元素的数组长度，这里的用法类似管道
% cat array.json | jq '.[0] | length'
3

# 嵌套读取数组元素
% cat array.json | jq '.[1][1]'
"eee"

# 也可以分开写
% cat array.json | jq '.[1] | .[1]'
"eee"

# 数组切片，[m:n] 包含 [m] 不包含 [n]
% cat array.json | jq '.[1][0:2]'
[
  "ddd",
  "eee"
]
```

#### 数组相关函数

#### 数组写入

### 哈希表相关操作

实例文件 hashtable.json：

```
{
  "h1": {
    "k1": "v1",
    "k2": "v2",
    "k3": "v3"
  },
  "h2": {
    "k4": "v4",
    "k5": "v5",
    "k6": "v6"
  }
}

```

#### 哈希表读取

```
# 读取哈希表长度
% cat hashtable.json | jq length
2

% cat hashtable.json | jq '.h1 | length'
3

# 读取哈希表中所有键，以数组形式返回
% cat hashtable.json | jq keys
[
  "h1",
  "h2"
]

# 判断键是否存在
% cat hashtable.json | jq 'has("h1")'
true
% cat hashtable.json | jq 'has("h3")'
false
% cat hashtable.json | jq '.h1 | has("k3")'
true

# 将值取出来
% cat hashtable.json | jq '.[]'
{
  "k1": "v1",
  "k2": "v2",
  "k3": "v3"
}
{
  "k4": "v4",
  "k5": "v5",
  "k6": "v6"
}

# 此处不能用 jq '.h1.[]'
% cat hashtable.json | jq '.h1 | .[]'
"v1"
"v2"
"v3"


```

#### 哈希表相关函数

#### 哈希表写入

### 内置运算

### 变量

### 总结

待完善。

### 参考

https://www.ibm.com/developerworks/cn/linux/1612_chengg_jq/index.html

