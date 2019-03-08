### 导读

很多时候，我们写的代码并不是只运行一次就不再用了，那就需要保存到文件里。我们通常称包含解释性编程语言代码的可执行文件为脚本文件，简称脚本。而在脚本内部，也会有一些可以复用的代码，我们可以把这样的代码写成函数，供其他部分调用。Zsh 中函数和脚本基本上一样的，可以认为脚本就是以文件名为函数名的函数。脚本和函数的编写方法基本相同，所以在一起讲。

先从函数开始，因为涉及更少的细节。

### 函数定义

```
# 一个很简单的函数
fun() {
    echo good
}

# 也可以在前边加一个 function 关键字
function fun() {
    echo good
}
```

这样就可以定义一个函数了。小括号一定是空的，即使函数有参数，也无需在里边写参数列表。

直接输入函数名即可调用函数。

```
fun() {
    echo good
}

% fun
good
```

用 unfunction 可以删除函数。

```
fun() {
    echo good
}

% unfunction fun
% fun
zsh: command not found: fun
```

### 参数处理

函数可以有参数，但 zsh 中无需显式注明有几个参数，直接读取即可。

```
fun() {
    echo $1 $2 $3
    echo $#
}

% fun aa
aa
1
% fun aa bb cc
aa bb cc
3
% fun aa bb cc dd
aa bb cc
4
```

$n 是第 n 个参数，$# 是参数个数。如果读取的时候没有对应参数传进来，那和读取一个未定义的变量效果是一样的。函数的参数只能是字符串类型，如果把整数、浮点数传进函数里，也会被转成字符串。可以把数组传给函数，然后数组中的元素会依次成为各个参数。

```
fun() {
    echo $1 $2 $3
    echo $#
}

% array=(11 22 33)
% fun $array
11 22 33
3
```

这样用的好处是可以更方便地处理带空格的参数。

```
# 遍历所有参数，$* 是包含所有参数的数组
fun() {
    for i ($*) {
        echo $i
    }
}

% fun a b c
a
b
c
```

可以用 $+n 快速判断第 n 个参数是否存在。

```
fun() {
    (($+1)) && {
        echo $1
    }
}
```

关于 `$*` 和 `$@`。在 bash 中， `$*` 和 `$@` 的区别是一个比较麻烦的事情，但在 zsh 中，通常没有必要使用 `$@`，所以不用踩这个坑。Bash 中需要使用 `$@` 的原因是如果使用 `$*` 并且参数中有空格的话，就分不清哪些空格是参数里的，哪些空格是参数之间的间隔符（bash 里的 `$*` 是一个字符串）。而如果使用 `"$*"` 的话，所有的参数都合并成一个字符串了。而 `"$@"` 可以保留参数中的空格，所以通常使用 `"$@"`。但是有些时候需要把所有参数拼接成一个字符串，那么又要使用 `"$*"`，所以很混乱。

而 zsh 中的 `$*` 会包括参数中的空格（zsh 里的 `$*` 是一个数组），所以效果和 bash 的 `"$@"` 是差不多的。另外在 zsh 中用 `"$*"` 和在 bash 中的 `"$*"` 效果一样，所以只用 `$*` 和 `"$*"` 就足够了。

### 函数嵌套

函数可以嵌套定义。

```
fun() {
    fun2() {
        echo $2
    }

    fun2 $1 $2
}

% fun aa bb
bb
```

fun2 函数是在 fun 执行过才会被定义的，但最外边也能直接访问 fun2 函数。如果想要最外边访问不了，可以在 fun 结束前调用 unfunction fun2 删除 fun2 函数。

### 返回值

函数需要返回一个代表函数是否正确执行的返回值，如果是 0，代表正确执行，如果不是 0，代表有错误。

```
#!/bin/zsh

fun() {
    (($+1)) && {
        return
    }

    return 1
}

% fun 111 && echo good
good
% fun || echo bad
bad

% fun
# 也可以用 $? 获取函数返回值
% echo $?
```

遇到 return 后，函数立即结束。return 即 return 0。

注意返回值不是用来返回数据的，如果函数需要将字符串、整数、浮点数等返回给调用者，直接用 echo 或者 print 等命令输出即可，然后调用者用 $(fun) 获取。如果需要返回数组或者哈希表，只能通过变量（全局变量或者函数所在层次的局部变量）传递。

```
fun() {
    echo 123.456
}

% echo $(($(fun) *2))
246.91200000000001
```

通过全局变量返回。

```
array=()
fun() {
    array=(aa bb)
}

% fun
% echo $array
aa bb
```

### 局部变量

在函数中可以直接读写函数外边的变量，并且在函数中定义的新变量在函数退出后依然存在。

```
str1=abcd

fun() {
    echo $str1
    str2=1234
}

% fun
abcd
% echo $str2
1234
```

这通常是不符合预期的。为了避免函数内的变量“渗透”到函数外，可以使用局部变量，使用 local 定义变量。

```
str1=abcd

fun() {
    echo $str1
    local str2=1234
}

% fun
abcd
% echo $str2

```

函数中的变量，除非确实需要留给外部使用，不然最好全部使用局部变量，避免引发 bug。

### 脚本

可以认为脚本也是一个函数，但它是单独写到一个文件里的。

test.zsh 内容。

```
#!/bin/zsh

echo good
```

这是一个非常简单的脚本文件。第一行是固定的，供系统找到 zsh 解释器，#! 后加 zsh 的绝对路径即可。如果需要使用环境变量访问，可以用 #!/bin/env zsh （或者 !/usr/bin/env zsh，如果 env 在 /usr/bin/ 里边）。

从第二行开始，就和函数中的内容一样了。上边函数体里的内容（去掉首尾行的 fun() { 和 }，都可以写在这里边。

执行的话，在 test.zsh 所在目录，运行 zsh test.zsh 加参数即可（就像调用了一个名为 zsh test.zsh 的函数。也可以 chmod u+x test.zsh 给它添加可执行权限后，直接运行 ./test.zsh 加参数。

脚本的参数和返回值的处理方法，和函数的完全一样，这里就不举例了。

但函数和脚本中执行的时候是有区别的，函数是在当前的 zsh 进程里执行（也可以调用的时候加小括号在子进程执行），而脚本是在新的子进程里执行，执行完子进程即退出了，所以脚本中的变量值外界是访问不到的，无需使用 local 定义（使用也没问题）。

### exit 命令

脚本可以使用 return 返回，也可以使用 exit 命令。exit 命令用法和 return 差不多，如果不加参数则返回 0。但在代码的任何地方，调用 exit 命令即退出脚本，即使是在一个嵌套很深的函数里边理调用的。

### 用 getopts 命令处理命令行选项

有时我们写的脚本需要支持比较复杂的命令行选项，比如 demo -i aa -t bb -cx ccc ddd，这样的话，手动处理就会很麻烦。可以使用内置的 getopts 命令。

```
#!/bin/zsh

# i: 代表可以接受一个带参数的 -i 选项
# c 代表可以接受一个不带参数的 -c 选项
while {getopts i:t:cv arg} {
    case $arg {
        (i)
        # $OPTARG 存放选项对应的参数
        echo $arg option with arg: $OPTARG
        ;;

        (t)
        echo $arg option with arg: $OPTARG
        ;;

        (c)
        echo $arg option
        ;;

        (v)
        echo version: 0.1
        ;;

        (?)
        echo error
        return 1
        ;;
    }
}

# $OPTIND 指向剩下的第一个未处理的参数
echo $*[$OPTIND,-1]

# 或者用 shift 把之前用过的参数移走
# shift $((OPTIND - 1))
# echo $*
```

运行结果：

```
% ./demo -i aaa -t bbb -cv ccc ddd
i option with arg: aaa
t option with arg: bbb
c option
version: 0.1
ccc ddd

# 可以只加部分选项
% ./demo -i aaa -v bbb ccc
i option with arg: aaa
version: 0.1
bbb ccc

# 可以一个选项也不加
% ./demo aaa bbb
aaa bbb

# 如果选项不带参数，多个选项可以合并到一个 - 后
% ./demo -i aaa -cv bbb ccc
i option with arg: aaa
c option
version: 0.1
bbb ccc

# 如果该带参数的选项不带参数，会报错
% ./demo -i aaa -t
i option with arg: aaa
./demo:3: argument expected after -t option
error

# 加了不支持的选项也会报错
% ./demo -i aaa -a bbb ccc
i option with arg: aaa
./demo:3: bad option: -a
error

# 如果该带参数的选项不带参数，然后后边紧接着另一个选项，那么选项会被当作参数
% ./demo -i -c aaa bbb
i option with arg: -c
aaa bbb
```

getopts 的使用还是很方便的，但它不支持长选项（如 --log aaa）。如果需要使用长选项，可以用 getopt 命令，它是一个外部命令，可以 man getopt 查看用法。

### 总结

本文简单介绍了函数和脚本的写法，重点是参数处理和返回值等等，还有很多没覆盖的地方，以后可能继续补充。

### 参考

https://my.oschina.net/lenglingx/blog/410565

### 更新历史

20170901：增加用 $? 获取函数返回值的内容。

20170902：增加“用 getopts 命令处理命令行选项”。
