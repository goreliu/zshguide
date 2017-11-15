### 导读

到目前为止，我们已经大致了解了 zsh 的语法特性，可以写一些功能不复杂的脚本了。但 shell 脚本主要的应用场景并不是闭门造车写独立的程序，而是和外部环境交互。所以要写出实用的脚本，要了解 zsh 如何和外部环境交互。这里的外部环境包括其他进程、文件系统、网络等等。本篇主要讲管道和重定向，这是和其他进程、文件系统等交互的基础。

本文中的命令主要是为了演示管道的用法，在实际脚本中通常不需要使用这些命令，因为可以用 zsh 代码直接实现。另外本系列文章不详细讲任何外部命令的用法，因为相关文档或者书籍特别多。如果看不懂本文的某些内容，可以暂时跳过，基本不影响其余部分的理解。


### 管道

管道是类 Unix 系统中的一个比较基础也特别重要的概念，它用于将一个程序的输出作为另一个程序的输入，进而两个程序的数据可以互通。如果只是使用管道，还是非常简单易懂的，并不需要了解管道的实现细节。

管道的基本用法：

```
% ls
git  tmp
# wc -l 功能是计算输入内容的行数
% ls | wc -l
2
```
| 即管道，在键盘上是主键盘区右侧 \ 对应的上档键字符。如果只输入 wc -l，wc 会等待用户输入，这时可以输入字符串，然后回车继续输入，直到按 ctrl + d 结束输入。然后 wc 会统计用户一共输入了多少行，然后输出行数。

```
# 敲 wc -l 回车后，依次按 a 回车 b 回车 ctrl + d
% wc -l
a
b
2
```

但如果前边有个管道符号，ls | wc -l，那么 wc 就不等待用户输入了，而是直接将 ls 的结果作为输入读取过来，然后统计行数，输出结果。

### 关于管道的更多细节

我们再运行一个简单的例子：

```
% cat | wc -l

# 查看 cat 进程打开的 fd
% ls -l /proc/$(pidof cat)/fd
total 0
lrwx------ 1 goreliu goreliu 0 2017-08-30 21:15 0 -> /dev/pts/1
l-wx------ 1 goreliu goreliu 0 2017-08-30 21:15 1 -> pipe:[2803]
lrwx------ 1 goreliu goreliu 0 2017-08-30 21:15 2 -> /dev/pts/1

# 查看 wc 进程打开的 fd
% ls -l /proc/$(pidof wc)/fd
total 0
lr-x------ 1 goreliu goreliu 0 2017-08-30 21:16 0 -> pipe:[2803]
lrwx------ 1 goreliu goreliu 0 2017-08-30 21:16 1 -> /dev/pts/1
lrwx------ 1 goreliu goreliu 0 2017-08-30 21:16 2 -> /dev/pts/1
```

cat 命令的效果是等待用户输入，等用户输入一行，它就把这行再输出来，直到用户按 ctrl - d。所以 cat | wc -l 也会等待用户输入。

我们看下 fd 的指向，/dev/ps1/1 是指向伪终端设备文件的，进程就是通过这个来读取用户的输入和输出自己的内容。0 是标准输入（即用户输入端），1 是标准输出（即正常情况的输出端），2 是错误输出（即异常情况的输出端）。但是 cat 的输出端指向了 一个管道，并且 wc 的 输入端指向了一个相同的管道，这代表两个进程的输入输出端是通过管道连接的。这种管道是匿名管道，即只在内核中存在，是没有对应的文件路径的。

### 重定向

重定向，指的便是 fd 的重定向，管道也是重定向的一种方法。但用得更多的是将进程的 fd 重定向到文件。

一个最简单的例子是输出内容到文件。

```
% echo abce > test.txt
% cat test.txt
abce
```

因为这个用法太常见了，大家可能习以为常了。我们依然来看下更多的细节。

```
% cat > test.txt

# 在另一个 zsh 中运行
% ls -l /proc/$(pidof cat)/fd
total 0
lrwx------ 1 goreliu goreliu 0 Aug 30 21:43 0 -> /dev/pts/1
l-wx------ 1 goreliu goreliu 0 Aug 30 21:43 1 -> /tmp/test.txt
lrwx------ 1 goreliu goreliu 0 Aug 30 21:43 2 -> /dev/pts/1
```

可以看到标准输出已经指向 test.txt 文件了。

除了标准输出可以重定向，标准输入（fd 0），错误输出（fd 2）也都可以。

```
% touch 0.txt 1.txt 2.txt
% sleep 1000 <0.txt >1.txt 2>2.txt

# 在另一个 zsh 中运行
% ls -l /proc/$(pidof sleep)/fd
total 0
lr-x------ 1 goreliu goreliu 0 Aug 30 21:46 0 -> /tmp/0.txt
l-wx------ 1 goreliu goreliu 0 Aug 30 21:46 1 -> /tmp/1.txt
l-wx------ 1 goreliu goreliu 0 Aug 30 21:46 2 -> /tmp/2.txt
```

<0.txt 是重定向标准输入，2>2.txt 是重定向错误输出，>1.txt（即 1>1.txt）是重定向到标准输出。然后我们看到 3 个文件已经各就各位，全部被重定向了。但因为 sleep 并不去读写任何东西，重定向它的输入输出没有什么意义。

### 更多重定向的用法

一个 fd 只能重定向到一个文件，一一对应。但在 zsh 中，我们可以把一个 fd 对应到多个文件。

```
% cat >0.txt >1.txt >2.txt
```

输入完成后，3 个文件的内容都更新了，这是怎么回事呢？

其实是 zsh 进程做了中介。

```
% pstree -p | grep cat
        `-tmux: server(1172)-+-zsh(1173)---cat(1307)---zsh(1308)

% ls -l /proc/1307/fd
total 0
lrwx------ 1 goreliu goreliu 0 Aug 30 21:57 0 -> /dev/pts/1
l-wx------ 1 goreliu goreliu 0 Aug 30 21:57 1 -> pipe:[2975]
lrwx------ 1 goreliu goreliu 0 Aug 30 21:57 2 -> /dev/pts/1

% ls -l /proc/1308/fd
total 0
l-wx------ 1 goreliu goreliu 0 Aug 30 21:58 12 -> /tmp/0.txt
l-wx------ 1 goreliu goreliu 0 Aug 30 21:58 13 -> /tmp/1.txt
lr-x------ 1 goreliu goreliu 0 Aug 30 21:58 14 -> pipe:[2975]
l-wx------ 1 goreliu goreliu 0 Aug 30 21:58 15 -> /tmp/2.txt
```

可以看到 cat 的标准输出是重定向到管道了，管道对面是 zsh 进程，然后 zsh 打开了那三个文件。实际将内容写入文件的是 zsh，而不是 cat。但不管是谁写入的，这个用法很方便。

标准输入、错误输出也可以重定向多个文件。

```
% echo good >0.txt >1.txt >2.txt

% cat <0.txt <1.txt <2.txt
good
good
good
```

给 cat 的标准输出重定向 3 个文件，它将 3 个文件的内容全部读取了出来。

除了能同时重定向 fd 到多个文件外，还可以同时重定向到管道和文件。

```
# 敲完 a b c 后 ctrl -d 退出
% cat >0.txt >1.txt | wc -l
a
b
c
3

% cat 0.txt 1.txt
a
b
c
a
b
c
```

可以看到输入的内容写入了文件，并且通过管道传给了 wc -l，不用说，这又是 zsh 在做背后工作，将数据分发给了文件和管道。所以在 zsh 中是不需要使用 tee 命令的。

### 命名管道

除了匿名管道，我们还可以使用命名管道，这样更容易控制。命名管道所使用的文件即 FIFO（First Input First Output，先入先出）文件。

```
# mkfifo 用来创建 FIFO 文件
% mkfifo fifo
% ls -l
prw-r--r-- 1 goreliu goreliu 0 2017-08-30 21:29 fifo|

# cat 写入 fifo
% cat > fifo

# 打开另一个 zsh，运行 wc -l 读取 fifo
% wc -l < fifo
```

然后在 cat 那边输入一些内容，按 ctrl - d 退出，wc 这边就会统计输入的行数。

在输入完成之前，我们也可以看一下 cat 和 wc 两个进程的 fd 指向哪里：

```
% ls -l /proc/$(pidof cat)/fd
total 0
lrwx------ 1 goreliu goreliu 0 Aug 30 21:35 0 -> /dev/pts/2
l-wx------ 1 goreliu goreliu 0 Aug 30 21:35 1 -> /tmp/fifo
lrwx------ 1 goreliu goreliu 0 Aug 30 21:35 2 -> /dev/pts/2

% ls -l /proc/$(pidof wc)/fd
total 0
lr-x------ 1 goreliu goreliu 0 Aug 30 21:34 0 -> /tmp/fifo
lrwx------ 1 goreliu goreliu 0 Aug 30 21:34 1 -> /dev/pts/1
lrwx------ 1 goreliu goreliu 0 Aug 30 21:34 2 -> /dev/pts/1
```

可以看到之前的匿名管道已经变成了我们刚刚创建的 fifo 文件，其他的并无不同。

### exec 命令的用法

说起重定向，就不得不提 exec 命令。exec 命令主要用于启动新进程替换当前进程以及对 fd 做一些操作。

用 exec 启动新进程：

```
% exec cat
```

看上去效果和直接运行 cat 差不多。但如果运行 ctrl + d 退出 cat，终端模拟器就关闭了，因为在运行 exec cat 的时候，zsh 进程将已经被 cat 取代了，回不去了。

但在脚本中很少直接这样使用 exec，更多情况是用它来操作 fd：

```
# 将当前 zsh 的错误输出重定向到 test.txt
% exec 2>test.txt
# 随意敲入一个不存在的命令，错误提示不出现了
% fdsafds
# 错误提示被重定向到 test.txt 里
% cat test.txt
zsh: command not found: fdsafds
```

更多用法：

| 用法          | 功能                            |
| ----------- | ----------------------------- |
| n>filename  | 重定向 fd n 的输出到 filename 文件     |
| n<filename  | 重定向 fd n 的输入为 filename 文件     |
| n<>filename | 同时重定向 fd n 的输入输出为 filename 文件 |
| n>&m        | 重定向 fd n 的输出到 fd m            |
| n<&m        | 重定向 fd n 的输入为 fd m            |
| n>&-        | 关闭 fd n 的输出                   |
| n<&-        | 关闭 fd n 的输入                   |

更多例子：

```
# 把错误输出关闭，这样错误内容就不再显示
% exec 2>&-
% fsdafdsa

% exec 3>test.txt
% echo good >&3
% exec 3>&-
# 关闭后无法再输出
% echo good >&3
zsh: 3: bad file descriptor

% exec 3>test.txt
# 将 fd 4 的输出重定向到 fd 3
% exec 4>&3
% echo abcd >&4
# 输出内容到 fd 4，test.txt 内容更新了
% cat test.txt
abcd
```

通常情况我们用 exec 主要为了重定向输出和关闭输出，比较少操作输入。

### 总结

本文讲了管道和重定向的基本概念和各种用法。Zsh 中的重定向还是非常灵活好用的，之后的文章会详细讲在实际场景中怎样使用。

### 参考

http://adelphos.blog.51cto.com/2363901/1601563

### 更新历史

20170901：增加“exec 命令的用法”。