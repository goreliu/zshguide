### 导读

就像我之前提到的，zsh 脚本是可以直接使用 socket 文件（UNIX domain socket 所使用）或者 TCP 和其他进程通信的。如果进程都在本地，用 socket 文件效率更高些，并且不要占用端口，权限也更好控制。如果是在不同机器，可以使用 TCP。

### Socket 文件

UNIX domain socket 是比管道更先进的进程通信方法，是全双工的方式，并且稳定性更好。但性能比管道差一些，不过一般性能瓶颈都不会出现在这里，不用考虑性能问题。而且在一个 socket 文件上可以建立多个连接，更容易管理。另外如果通信方式从 socket 文件改成 TCP，只需要修改很少的代码（建立和关闭连接的代码稍微改一下），而从管道改成 TCP 则要麻烦很多。

所以建议用 zsh 写进程交互脚本的话，直接使用 socket 文件，而不是命名管道（匿名管道就能满足需求的简单场景忽略不计）。

Socket 文件的用法：

```
# 监听连接端
# 首先要加载 socket 模块
% zmodload zsh/net/socket

% zsocket -l test.sock
% listenfd=$REPLY
# 此处阻塞等待连接
% zsocket -a $listenfd
# 连接建立完成
% fd=$REPLY
% echo $fd
5

# 然后 $fd 就可读可写
% cat <&$fd
good
```

```
# 发起连接端
# 首先要加载 socket 模块
% zmodload zsh/net/socket

% zsocket test.sock
# 连接建立完成
% fd=$REPLY
% echo $fd
4

# 然后 $fd 就可读可写
% echo good >&$fd
```

连接建立后，怎么用就随意了。实际使用时，要判断 fd 看连接是否正常建立了。通常使用 socket 文件要比在网络环境使用 TCP 稳定性高很多，一般不会连接中断或者出其他异常。另外可以在 zsocket 后加 -v 参数，查看详细的信息（比如使用的 fd 号）。

关闭连接：

```
# 发起连接端
# fd 是之前存放 fd 号的变量，不需要加 $
% exec {fd}>&-

# 监听连接端
% exec {listenfd}>&-
% exec {fd}>&-
# 删除 socket 文件即可，如果下次再使用会重新创建，该文件不能重复使用
% rm test.sock
```

### TCP

使用 TCP 连接的方式和使用 socket 文件基本一样。

```
# 监听连接端
# 首先要加载 tcp 模块
% zmodload zsh/net/tcp

% ztcp -l 1234
% listenfd=$REPLY
# 此处阻塞等待连接
% ztcp -a $listenfd
# 连接建立完成
% fd=$REPLY
% echo $fd
3

# 然后 $fd 就可读可写
% cat <&$fd
good
```

```
# 发起连接端
# 首先要加载 tcp 模块
% zmodload zsh/net/tcp

% ztcp 127.0.0.1 1234
# 连接建立完成
% fd=$REPLY
% echo $fd
3

# 然后 $fd 就可读可写
% echo good >&$fd
```

关闭连接：

```
# 发起连接端
# fd 是之前存放 fd 号的变量
% ztcp -c $fd

# 监听连接端
% ztcp -c $listenfd
% ztcp -c $fd
```

### 程序样例

recv_tcp，监听指定端口，并输出发送过来的消息。使用方法：recv_tcp 端口

```
#!/bin/zsh

zmodload zsh/net/tcp

(($+1)) || {
    echo "Usage: ${0:t} port"
    exit 1
}

ztcp -l $1
listenfd=$REPLY

[[ $listenfd == <-> ]] || exit 1

while ((1)) {
    ztcp -a $listenfd
    fd=$REPLY
    [[ $fd == <-> ]] || continue

    cat <&$fd
    ztcp -c $fd
}
```

send_tcp，用来向指定机器的指定端口发一条消息。使用方法：send_tcp 机器名  端口 消息 （机器名可选，如果没有则发到本机，消息可以包含空格）

```
#!/bin/zsh

zmodload zsh/net/tcp

(($# >= 2)) || {
    echo "Usage: ${0:t} [hostname] port message"
    exit 1
}

if [[ $1 == <0-65535> ]] {
    ztcp 127.0.0.1 $1
} else {
    ztcp $1 $2
    shift
}

fd=$REPLY
[[ "$fd" == <-> ]] || exit 1

echo ${*[2,-1]} >&$fd
ztcp -c $fd
```

### 总结

本文介绍了使用 socket 文件或者 TCP 来实现两个脚本之间通信的方法。
