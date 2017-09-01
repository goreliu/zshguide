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
├── bbb.txt
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

功能：删除当前目录以及字母路下所有的重复文件（根据 md5 判断，不是很严谨）。

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

### 总结

本文讲解了几个简单的 zsh 脚本，后续可能会补充更多个。
