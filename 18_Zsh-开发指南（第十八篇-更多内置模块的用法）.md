### 导读

除了 zsh/mathfunc、zsh/net/socket、zsh/net/tcp，zsh 还内置了一些其他的内置模块。本文简单讲几个比较常用的模块。

### 模块的使用方法

```
# 使用 zmodload 加模块名来加载模块
% zmodload zsh/mathfunc

# 如果不加参数，可以查看现在已经加载了的模块
% zmodload
zsh/complete
zsh/complist
zsh/computil
zsh/main
zsh/mathfunc
zsh/parameter
zsh/stat
zsh/zle
zsh/zutil

# 加 -u 参数可以卸载模块
% zmodload -u zsh/mathfunc

# 还有其他参数，可以补全查看帮助，不详细介绍了
% zmodload -<tab>
 -- option --
-A  -- create module aliases
-F  -- handle features
-I  -- define infix condition names
-L  -- output in the form of calls to zmodload
-P  -- array param for features
-R  -- remove module aliases
-a  -- autoload module
-b  -- autoload module for builtins
-c  -- autoload module for condition codes
-d  -- list or specify module dependencies
-e  -- test if modules are loaded
-f  -- autoload module for math functions
-i  -- suppress error if command would do nothing
-l  -- list features
-m  -- treat feature arguments as patterns
-p  -- autoload module for parameters
-u  -- unload module
```

### 日期时间相关模块

我们知道使用 date 命令可以查看当前时间，也可以用来做日期时间的格式转换。但如果脚本里需要频繁地读取或者处理时间（比如打日志的时候，每一行加一个时间戳），那么调用 date 命令的资源消耗就太大了。Zsh 的 zsh/datetime 模块提供和 date 命令类似的功能。

```
% zmodload zsh/datetime

# 输出当前时间戳（从 1970 年年初到现在的秒数），和 date +%s 一样
% echo $EPOCHSECONDS
1504231297

# 输出高精度的当前时间戳，浮点数
% echo $EPOCHREALTIME
1504231373.9913284779

# 输出当前时间戳的秒和纳秒部分，是一个数组
# 可以用 epochtime[1] 和 epochtime[2] 分别读取
% echo $epochtime
1504231468 503125900

# 安装指定格式输出当前时间，和 date +%... 效果一样
# 格式字符串可以 man date 或者 man strftime 查看
% strftime "%Y-%m-%d %H:%M:%S (%u)" $EPOCHSECONDS
2017-09-01 10:06:47 (5)

# 如果加了 -s str 参数，将指定格式的时间存入 str 变量而不输出
% strftime -s str "%Y-%m-%d %H:%M:%S (%u)" $EPOCHSECONDS
% echo $str
2017-09-01 10:10:58 (5)

# 如果加了 -r 参数，从指定的时间字符串反解出时间戳，之前操作的逆操作
# 也可以同时加 -s 参数来讲结果存入变量
% strftime -r "%Y-%m-%d %H:%M:%S (%u)" "2017-09-01 10:10:58 (5)"
1504231858
```

这基本覆盖了 date 的常用功能，而运行速度比 date 命令快很多。

### 读写 gdbm 数据库

有时我们的脚本需要将某些数据持久化到本地文件，但像哈希表之类的数据，如果存放到普通文件里，载入和保存的资源消耗都比较大，而且如果脚本突然异常退出，数据会丢失。而且某些时候，我们可能需要操作一个巨大的哈希表，并不能全部将它载入到内存中。那么我们可以使用 gdbm 数据库文件。

Gdbm 是一个很轻量的 Key-Value 数据库，可以认为它就像一个保存在文件里的哈希表。Zsh 的 zsh/db/gdbm 模块可以很方便地读写 gdbm 数据库文件。

```
% zmodload zsh/db/gdbm

# 声明数据库文件对应的哈希表
% local -A sampledb
# 创建数据库文件，文件名是 sample.gdbm，对应 sampledb 哈希表
# 如果该文件已经存在，则会继续使用该文件
% ztie -d db/gdbm -f sample.gdbm sampledb

# 然后正常使用 sampledb 哈希表即可，数据会同步写入到数据库文件中
% sampledb[k1]=v1
% sampledb+=(k2 v2 k3 v3)
% echo ${(kv)sampledb}
k1 v1 k2 v2 k3 v3

# 获取数据库文件路径
% zgdbmpath sampledb
% echo $REPLY
/home/goreliu/sample.gdbm

# 释放数据库文件
% zuntie -u sampledb


# 也可以用只读的方式加载数据库文件
% ztie -r -d db/gdbm -f sample.gdbm sampledb
# 但这样的话，需要用 zuntie -u 释放数据库文件
% zuntie -u sampledb
```

如果数据量比较大，或者有比较特别的需求，要先了解下 gdbm 是否符合自己的场景再使用。

### 调度命令

有时我们需要在未来的某个时刻运行某一个命令。虽然也可以 sleep 然后运行，但这样要多占两个进程，而且不好控制（比如要取消运行其中的某一个）。Zsh 的 zsh/sched 模块用于调度命令的运行。

```
% zmodload zsh/sched

# 5 秒后运行 ls 命令
% sched +5 ls
# 可以随便做些别的
% date
Fri Sep  1 10:36:16 DST 2017
# 五秒后，ls 命令被运行
git  sample.gdbm  tmp

# 不加参数可以查看已有的待运行命令
% sched
  1 Fri Sep  1 21:16:05 date
  2 Fri Sep  1 21:16:30 date
  3 Fri Sep  1 21:17:12 date

# -n 可以去除第 n 个待运行命令
% sched -2
% sched
  1 Fri Sep  1 21:16:05 date
  2 Fri Sep  1 21:17:12 date
```

### 底层的文件读写命令

有时我们可能需要更精细地操作文件，zsh 提供了一个 zsh/system 模块，里边包含一些底层的文件读写命令（对应 open、read、write 等系统调用）。使用这些函数，可以更精细地控制文件的读写，比如控制每次读写的数据量、从中间位置读写、上文件锁等等。这些命令的用法比较复杂，参数也比较多，这里就不列出了。如果需要使用，可以 man zshmodules 然后搜索 zsh/system 查看文档。

函数列表：sysopen、sysread、sysseek、syswrite、zsystem flock、systell、syserror

### 其他模块

其余的在脚本编写方面可能用的上的模块还有：

zsh/pcre（使用 pcre 正则表达式库，默认使用的是 POSIX regex 库）

zsh/stat（内部的 stat 命令，可用于取代 stat 命令）

zsh/zftp（内置的 ftp 客户端）

zsh/zprof（Zsh 脚本的性能追踪工具）

zsh/zpty（操作 pty 的命令）

zsh/zselect（select 系统调用的封装）

可以用 man zshmodules 查看。

### 自己编写模块

如果因为性能等因素，要自己写 zsh 模块来调用，也是比较方便的。Zsh 的源码中 Src/Modules 是模块目录，里边有一个实例模块 example（example.c 和 example.mdd 文件）。可以参考代码编写自己的模块，难度并不是很大。

### 总结

本文介绍了几个比较常用的 zsh 内置模块，以后可能继续补充更多模块的用法。
