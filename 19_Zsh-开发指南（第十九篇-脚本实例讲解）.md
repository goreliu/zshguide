### 导读

本文将讲解一些比较简单的 zsh 脚本实例。

### 实例一：复制一个目录的目录结构

功能：将一个目录及它下边的所有目录复制到另一个目录中（即创建同名目录），但不复制目录下的其他类型文件。

例子：

```
src 的目录结构：

src
├── a
├── b
│   ├── 1.txt
│   └── 2
│       └── 3.txt
├── c.txt
├── d
├── e f
│   └── g
│       └── 4.txt
└── g h -> e f

要构造一个 dst 目录，只包含 src 下的目录，内容如下：

dst
└── src
    ├── a
    ├── b
    │   └── 2
    ├── d
    └── e f
        └── g
```

思路：

1. 首先需要先将 src 目录下的目录名筛选出来，可以用 `**/*(/)` 匹配。
2. 然后用 `mkdir -p` 在 dst 目录中创建对应的目录。

```
# 参数 1：src 目录
# 参数 2：待创建的 dst 目录

#!/bin/zsh

for i ($1/**/*(/)) {
    # -p 参数是递归创建目录，这样不用考虑目录的创建顺序
    mkdir -p $2/$i
}
```

### 实例二：寻找不配对的文件

功能：需要当前目录下有一些 .txt 和 .txt.md5sum 的文件，需要寻找出没有对应的 .md5sum 文件的 .txt 文件。（实际的场景是寻找已经下载完成的文件，未下载完的文件都对应某个带后缀的文件。）

例子：

```
当前目录的所有文件：

aa.txt
bb.txt
bb.txt.md5sum
cc dd.txt
cc dd.txt.md5sum
ee ff.txt.md5sum
gg.txt
hh ii.txt

需要找出没有对应 .md5sum 的 .txt 文件：
aa.txt
gg.txt
hh ii.txt
```

思路：

1. 找到所有 .md5sum 文件，然后把文件名中的 .md5sum 去掉，即为那些需要排除的 .txt 文件（a）。
2. 所有的文件，排除掉 .m5sum 文件，再排除掉 a，即结果。

实现：

```
#!/bin/zsh

all_files=(*)
bad_files=(*.md5sum)
bad_files+=(${bad_files/.md5sum})

# 数组差集操作
echo ${all_files:|bad_files}
```

### 实例三：用 sed 批量重命名文件

功能：用形如 sed 命令的用法批量重命名文件。

例子：

```
# 实现 renamex 命令，接受的第一个参数为 sed 的主体参数，其余参数是文件列表
# 效果是根据 sed 对文件名的修改重命名这些文件

% tree
.
├── aaa_aaa.txt
├── aaa.txt
├── ccc.txt
└── xxx
    ├── aaa bbb.txt
    └── bbb ccc.txt

% renamex s/aaa/bbb/g **/*
'aaa_aaa.txt' -> 'bbb_bbb.txt'
'aaa.txt' -> 'bbb.txt'
'xxx/aaa bbb.txt' -> 'xxx/bbb bbb.txt'

% tree
.
├── bbb_bbb.txt
├── bbb.txt
├── ccc.txt
└── xxx
    ├── bbb bbb.txt
    └── bbb ccc.txt
```

思路：

1. 要找出所有的文件名，然后用 sed 替换成新文件名。
2. 如果文件名有变化，用 mv 命令移动

实现：

```
#!/bin/zsh

(($+2)) || {
    echo 'Usage: renamex s/aaa/bbb/g *.txt'
    return
}

for name ($*[2,-1]) {
    local new_name="$(echo $name | sed $1)"
    [[ $name == $new_name ]] && continue
    mv -v $name $new_name
}
```

### 实例四：根据文件的 md5 删除重复文件

功能：删除当前目录以及子目录下所有的重复文件（根据 md5 判断，不是很严谨）。

思路：

1. 用 md5sum 命令计算所有文件的 md5。
2. 使用哈希表判断 md5 是否重复，删除哈希表里已经有 md5 的后续文件。

实现：

```
#!/bin/zsh

# D 是包含以 . 开头的隐藏文件
local files=("${(f)$(md5sum **/*(.D))}")
local files_to_delete=()
local -A md5s

for i ($files) {
    # 取前 32 位，即 md5 的长度
    local md5=$i[1,32]

    if (($+md5s[$md5])) {
        # 取 35 位之后的内容，即文件路径，md5 后边有两个空格
        files_to_delete+=($i[35,-1])
    } else {
        md5s[$md5]=1
    }
}

(($#files_to_delete)) && rm -v $files_to_delete
```

### 实例五：转换 100 以内的汉字数字为阿拉伯数字

功能：转换 100 以内的汉字数字为阿拉伯数字，如六十八转换成 68。

思路：

1. 建一个哈希表存放汉字与数字的对应关系。
2. 比较麻烦的是“十”，在不同的位置，转换成的数字不同，需要分别处理。

实现：

```
#!/bin/zsh

local -A table=(
零 0
一 1
二 2
三 3
四 4
五 5
六 6
七 7
八 8
九 9
)

local result

if [[ $1 == 十 ]] {
    result=一零
} elif [[ $1 == 十* ]] {
    result=${1/十/一}
} elif [[ $1 == *十 ]] {
    result=${1/十/零}
} elif [[ $1 == *十* ]] {
    result=${1/十}
} else {
    result=$1
}

for i ({1..$#result}) {
    result[i]=$table[$result[i]]

    if [[ -z $result[i] ]] {
        echo error
        return 1
    }
}

echo $result

运行结果：

% ./convert 一
1
% ./convert 十
10
% ./convert 十五
15
% ./convert 二十
20
% ./convert 五十六
56
% ./convert 一百
error
```

### 实例六：为带中文汉字数字的文件名重命名成以对应数字开头

功能：见下边例子。

例子：

```
当前目录有如下文件：

Zsh-开发指南（第一篇-变量和语句）.md
Zsh-开发指南（第七篇-数值计算）.md
Zsh-开发指南（第三篇-字符串处理之转义字符和格式化输出）.md
Zsh-开发指南（第九篇-函数和脚本）.md
Zsh-开发指南（第二篇-字符串处理之常用操作）.md
Zsh-开发指南（第五篇-数组）.md
Zsh-开发指南（第八篇-变量修饰语）.md
Zsh-开发指南（第六篇-哈希表）.md
Zsh-开发指南（第十一篇-变量的进阶内容）.md
Zsh-开发指南（第十七篇-使用-socket-文件和-TCP-实现进程间通信）.md
Zsh-开发指南（第十三篇-管道和重定向）.md
Zsh-开发指南（第十九篇-脚本实例讲解）.md
Zsh-开发指南（第十二篇-[[-]]-的用法）.md
Zsh-开发指南（第十五篇-进程与作业控制）.md
Zsh-开发指南（第十八篇-更多内置模块的用法）.md
Zsh-开发指南（第十六篇-alias-和-eval-的用法）.md
Zsh-开发指南（第十四篇-文件读写）.md
Zsh-开发指南（第十篇-文件查找和批量处理）.md
Zsh-开发指南（第四篇-字符串处理之通配符）.md

需要重命名成这样：

01_Zsh-开发指南（第一篇-变量和语句）.md
02_Zsh-开发指南（第二篇-字符串处理之常用操作）.md
03_Zsh-开发指南（第三篇-字符串处理之转义字符和格式化输出）.md
04_Zsh-开发指南（第四篇-字符串处理之通配符）.md
05_Zsh-开发指南（第五篇-数组）.md
06_Zsh-开发指南（第六篇-哈希表）.md
07_Zsh-开发指南（第七篇-数值计算）.md
08_Zsh-开发指南（第八篇-变量修饰语）.md
09_Zsh-开发指南（第九篇-函数和脚本）.md
10_Zsh-开发指南（第十篇-文件查找和批量处理）.md
11_Zsh-开发指南（第十一篇-变量的进阶内容）.md
12_Zsh-开发指南（第十二篇-[[-]]-的用法）.md
13_Zsh-开发指南（第十三篇-管道和重定向）.md
14_Zsh-开发指南（第十四篇-文件读写）.md
15_Zsh-开发指南（第十五篇-进程与作业控制）.md
16_Zsh-开发指南（第十六篇-alias-和-eval-的用法）.md
17_Zsh-开发指南（第十七篇-使用-socket-文件和-TCP-实现进程间通信）.md
18_Zsh-开发指南（第十八篇-更多内置模块的用法）.md
19_Zsh-开发指南（第十九篇-脚本实例讲解）.md
```

思路：

1. 首先需要写将汉字数字转成阿拉伯数字的函数。
2. 然后需要从文件名中截取汉字数字，然后转成阿拉伯数字。
3. 拼接文件名，然后移动文件。

实现：

```
#!/bin/zsh

# 转换数字的逻辑和上一个实例一样

local -A table=(
零 0
一 1
二 2
三 3
四 4
五 5
六 6
七 7
八 8
九 9
)

convert() {
    local result

    if [[ $1 == 十 ]] {
        result=一零
    } elif [[ $1 == 十* ]] {
        result=${1/十/一}
    } elif [[ $1 == *十 ]] {
        result=${1/十/零}
    } elif [[ $1 == *十* ]] {
        result=${1/十}
    } else {
        result=$1
    }

    for i ({1..$#result}) {
        result[i]=$table[$result[i]]

        if [[ -z $result[i] ]] {
            echo error
            return 1
        }
    }

    echo $result
}

for i (Zsh*.md) {
    # -Z 2 是为了在前边补全一个 0
    # 汉字数字的起始位置是固定的，直接数即可，不固定的话也可以用去除法
    # 汉字数字的终止位置不固定，直接把“篇”以后的内容全去除
    local -Z 2 num=$(convert ${i[11,-1]/%篇*})
    mv -v $i ${num}_$i
}
```

### 总结

本文讲解了几个简单的 zsh 脚本，后续可能会补充更多个。
