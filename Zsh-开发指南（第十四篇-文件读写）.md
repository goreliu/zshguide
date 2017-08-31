### 导读

之前我们也偶尔接触过读写文件的方法，本篇会系统讲读写文件的各种方法。

### 写文件

写文件要比读文件简单一些，最常用的用法是使用 > 直接将命令的输出重定向到文件。如果文件存在，内容会被覆盖；如果文件不存在，会被创建。

```
% echo abc > test.txt
```

如果不想覆盖之前的文件内容，可以追加写入：

```
% echo abc >> test.txt
```

这样如果文件存在，内容会被追加写入进去；如果文件不存在，也会被创建。

#### 创建文件

有时我们只想先创建个文件，等以后需要的时候再写入。

touch 命令用于创建文件（普通文件）：

```
% touch test1.txt test2.txt

# 或者用 echo 输出重定向，效果和 touch 一样
# 加 -n 是因为不加的话 echo 会输出一个换行符
% echo -n >>test1.txt >>test2.txt

# 或者使用输入重定向
% >>test1.txt >>test2.txt </dev/null

# mkdir 用来创建目录，如果需要在新目录创建文件
% mkdir dir1 dir2
```

如果文件已经存在，touch 命令会更新它的时间（mtime、ctime、atime 一起更新，其余两种方法不会）到当前时间。另外下边的清空文件方法，也都可以用来创建文件。touch 命令的使用比较方便，但如果想尽量少依赖外部命令，可以使用后两种方法。

因为文件创建过程通常不存在性能瓶颈，不用过多考虑性能因素。如果需要创建大量文件，可以在自己的环境分别用这几种方法试验几次，看需要多少时间。

我在树莓派 3B 简单测试一下：

```
# 三个脚本，分别创建 1000 个文件
% cat test1 test2 test3
#!/bin/zsh

touch test1{1..1000}.txt
#!/bin/zsh

echo -n >>test2{1..1000}.txt
#!/bin/zsh

>>test3{1..1000}.txt </dev/null
```

```
# 运行了几次，结果差不多
% time ./test1; time ./test2; time ./test3
./test1  0.02s user 0.03s system 86% cpu 0.058 total
./test2  0.02s user 0.02s system 70% cpu 0.056 total
./test3  0.03s user 0.01s system 72% cpu 0.055 total
```

另外如果文件数量太多的话，方法二、三要按批次创建，因为一个进程能打开的 fd 总数是有上限的。

#### 清空文件

有时我们需要清空一个现有的文件：

```
# 使用 echo 输出重定向
% echo -n >test.txt

# 使用输入重定向
% >test.txt </dev/null

# 也可以使用 truncate 命令清空文件
% truncate -s 0 test.txt
```

通常使用第一种方法即可，比较简单易懂。非特殊场景尽量不要用像 truncate 这样不常见的命令。

#### 删除文件

删除文件的方法比较单一，用 rm 命令即可。

```
% rm test1.txt test2.txt

# -f 参数代表即使文件不存在也不报错
% rm -f test1.txt test2.txt

# -r 参数可以递归删除目录和文件
% rm -r dir1 dir2 test*.txt

# -v 参数代表 rm 会输出删除文件的过程
% rm -v test*.txt
removed 'test1.txt'
removed 'test2.txt'
```

删除文件必须借助 rm 命令。如果一定要不依赖外部命令的话，zsh/files 模块里也有一个 rm 命令，可以用 zmodload zsh/files 加载，然后 rm 就变成了内部命令，用法基本相同。

```
% zmodload zsh/files
% which -a rm
rm: shell built-in command
/usr/bin/rm
```

此外 zsh/files 中还有内置的 chgrp、chown、ln、mkdir、mv、rmdir、sync 命令。如果不想依赖外部命令，或者系统环境出问题了用不了外部命令，可以使用这些。这可以作为命令不存在或者因为命令本身问题执行异常的一个 fallback 方案，来提高脚本的健壮性。

#### 多行文本写入

通常我们写文件时不会每一行都单独写入，这样效率太低。

可以先把字符串拼接起来，然后一次性写入，这样比多次写入效率更高：

```
% str=ab
% str+="\ncd"
% str +="\n$str"

echo $str > test.txt
```

可以直接把数组写入到文件，每行一个元素：

```
% array=(aa bb cc)

% print -l $array > test.txt
```

如果是将一段内容比较固定的字符串写入到文件，可以这样：

```
# 在脚本中也是如此，第二行以后的行首 > 代表换行，非输入内容
# <<EOF 代表遇到 EOF 时会终止输入内容
# 里边也可以使用变量
% > test.txt <<EOF
> aa
> bb
> cc dd
> ee
> EOF

% cat test.txt
aa
bb
cc dd
ee
```

#### 用 mapfile 读写文件

如果不喜欢使用重定向符号，还可以用哈希表来操作文件。Zsh 有一个 zsh/mapfile 模块，用起来很方便：

```
% zmodload zsh/mapfile

# 这样就可以创建文件并写入内容，如果文件存在则会被覆盖
% mapfile[test.txt]="ab cd"
% cat test.txt
ab cd

# 判断文件是否存在
% (($+mapfile[test.txt])) && echo good
good

# 读取文件
% echo $mapfile[test.txt]
ab cd

# 删除文件
% unset "mapfile[test.txt]"

# 遍历文件
% for i (${(k)mapfile}) {
> echo $i
> }
test1.txt
test2.txt
```

#### 从文件中间位置写入

有时我们需要从一个文件的中间位置（比如从第 100 的字符或者第三行开始）继续写入，覆盖之后的内容。Zsh 并不直接提供这样的方法，但我们可以迂回实现，先用 truncate 命令把文件截断，然后追加写。如果文件后边的内容还需要保留，可以在截断之前先读取进来（见下文读文件部分的例子），最后再写回去。

```
% echo 1234567890 > test.txt
# 只保留前 5 个字符
% truncate -s 5 test.txt
% cat test.txt
12345 
% echo abcde >> test.txt
% cat test.txt
12345abcde
```

### 读文件

#### 读取整个文件

读取整个文件比较容易：

```
% str=$(<test.txt)
% echo $str
aa
bb
cc dd
ee
```

#### 按行遍历文件

如果文件比较大，那读取整个文件会消耗很多资源，可以按行遍历文件内容：

```
% while {read i} {
> echo $i
> } <test.txt
aa
bb
cc dd
ee
```

read 命令是从标准输入读取一行内容，把标准输入重定向后，就变成了从文件读取。

#### 读取指定行

如果只需要读取指定的某行或者某些行，不需要用上边的方法加自己计数。

```
# (f)2 是读取第二行
% echo ${"$(<test.txt)"[(f)2]}
bb
```

#### 读取文件到数组

读取文件内容到数组中，每行是数组的一个元素：

```
% array=(${(f)"$(<test.txt)"})
```

#### 读取指定数量的字符

有时我们需要按字节数来读取文件内容，而不是按行读取。

```
% cat test.txt
1234567890
# -k5 是只最多读取 5 个字节，-u 0 是从 fd 0 读取，不然会卡住
% read -k 5 -u 0 str <test.txt
% echo $str
12345
```

#### 向文件中间插入内容

有时我们会遇到比较麻烦的场景，在某个文件中间插入一些内容，而前后的内容保持不变。

Zsh 并没有直接提供这样的功能，但我们可以迂回实现。

```
% echo -n 1234567890 > test.txt
# 先全部读进来
% str=$(<test.txt)
# 截断文件
% truncate -s 5 test.txt
# 插入内容
% echo -n abcde >> test.txt
# 将后半部分文件追加回去
% echo -n $str[6,-1] >> test.txt
% cat test.txt
12345abcde67890
```

但如果比较比较大的话，就不能将整个文件全部读进来，可以先在循环里用 read -k num 一次读固定数量的字符，然后写入一个中间文件，然后再 truncate 原文件，插入内容。最后再 cat 中间文件 >> 原文件 追加原来的后半部分内容即可。

另外这种从文件中间写入或者读取内容的场景，都可以使用 dd 命令实现，可以自行搜索 dd 命令的用法。

### 总结

本文比较详细地介绍了各种读写文件的方法，基本可以覆盖常用的场景。
