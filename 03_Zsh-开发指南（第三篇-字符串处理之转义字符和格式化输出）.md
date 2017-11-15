### 导读

上一篇讲了 zsh 的常用字符串操作，这篇开始讲更为琐碎的转义字符和格式化输出相关内容。包括转义字符、引号、`print`、`printf` 的使用等等。其中很多内容没有必要记忆，作为手册参考即可。

### 转义字符

转义字符是很多编程语言中都有的概念，它主要解决某些字符因为没有对应键盘按键无法直接输出、字符本身有特殊含义（比如 `\`、`"`）或者显示不直观（比如难以区别多个空格和一个 tab）等问题。

最常用的转义字符是 `\n`（换行）、`\r`（回车）、`\t`（tab）。

直接用 `echo`、`print` 或者 `printf` 内置命令都可以正常输出转义字符，但包括转义字符的字符串需要用引号（单双引号都可以）扩起来。

```
% echo 'Hello\n\tWorld'
Hello
        World
```

常用转义字符对照表，不常用的可以去查 ASCII 码表，然后使用 `\xnn`（如 `\x14`）。

| 转义字符  | 含义     | ASCII 码值（十六进制） |
| ----- | ------ | -------------- |
| \n    | 换行     | 0a             |
| \r    | 回车     | 0d             |
| \t    | tab    | 09             |
| \\\\  | \      | 5c             |
| \\`   | `      | 60             |
| \\xnn | 取决于 nn | nn             |

可以用 `hexdump` 命令查看字符的 ASCII 码值。

```
% echo ab= | hexdump -C
00000000  61 62 3d 0a                                       |ab=.|
00000004
```

还有一些字符是可选转义（通常有特殊含义的字符都是如此）的，比如空格、`"`、`'`、`*`、`~`、`$`、`&`、`(`、`)`、`[`、`]`、`{`、`}`、`;`、`?` 等等，即如果在引号里边则无需转义（即使转义也不出错，转义方法都说前边加一个 `\`），但如果在引号外边则需要转义。谨慎起见，包含半角符号的字符串全部用引号包含即可，可以避免不必要的麻烦。

可以这样检查一个字符在空格外是否需要转义，输出的字符中前边带 `\` 的都是需要的。

```
% str='~!@#$%^&*()_+-={}|[]:;<>?,./"'
# -r 选项代表忽略字符串中的转义符合
# ${(q)str} 功能是为字符串中的特殊符号添加转义符号
% print -r ${(q)str}
\~\!@\#\$%\^\&\*\(\)_+-=\{\}\|\[\]:\;\<\>\?,./\"
```

### 单引号

单引号的左右主要是为了避免字符串里的特殊字符起作用。在单引号中，只有一个字符需要转义，转义符号 `\` 。所以如果字符串里包含特殊符号时，最好使用单引号包含起来，避免不必要的麻烦。如果字符串需要包含单引号，可以使用这几种方法。

```
# 用双引号包含
% echo "a'b"
a'b

# 用转义符号
% echo a\'b
a'b

# 同时使用单引号和转义符号，用于包含单引号和其他特殊符号的场景
% echo 'a"\'\''b*?'
a"\'b*?
```

### 双引号

双引号的作用类似单引号，但没有单引号那么严格，有些特殊字符在双引号里可以继续起作用。

```
# 以使用变量
% str=abc
% echo "$str"
abc

# 可以使用 $( ) 运行命令
% echo "$(ls)"
git
tmp

# 可以使用 ` ` 运行命令，不建议在脚本里使用 ` `
% echo "`date`"
Mon Aug 28 09:49:11 CST 2017

# 可以使用 $(( )) 计算数值
% echo "$((1 + 2))"
3

# 可以使用 $[ ] 计算数值
% echo "$[1 + 2]"
3
```

简单说，`$` 加各种东西的用法在双引号里都是可以正常使用的，而其他特殊符号（比如 `*`、`?`、`>`）的功能通常不可用。

### 反引号

反引号是用来运行命令的，它会返回命令结果，以便保存到变量等等。

```
% str=`ls`
% echo $str
git
tmp

# 完全可以用 $( ) 取代
% str=$(ls)
% echo $str
git
tmp
```

反引号的功能和 `$( )` 功能基本一样，但 `$( )` 可以嵌套，而反引号不可以，而且反引号看起来更费事，某些字体中的反引号和单引号差别不大。所以在脚本里不建议使用反引号。

### print 命令用法

`print` 是类似 `echo` 的内部命令（`echo` 命令很简单，不作介绍），但功能比 `echo` 强大很多。完全可以使用 `print` 代替 `echo`。

不加参数的 `print` 和 `echo` 的功能基本一样，但如果字符串里包含转义字符，某些情况可能不一致。如果需要输出转义字符，尽量统一使用 `print`，避免不一致导致的麻烦。

```
% print 'Line\tone\n\Line\ttwo'
Line    one
Line    two

# echo 的输出和 print 不一致
% echo 'Line\tone\n\Line\ttwo'
Line    one
\Line   two
```

`print` 有很多参数，在 zsh 里输入 `print -` 然后按 tab 即可查看选项帮助（如果没有效果，需要配置 `~/.zshrc` 里的补全选项，网上有很多现成的配置）。

```
# - 后直接按 tab，C 是补全上去的
% print -C
 -- option --
-C  -- print arguments in specified number of columns
-D  -- substitute any arguments which are named directories using ~ notation
-N  -- print arguments separated and terminated by nulls
...
```

### print 命令选项功能介绍

这里以常用程度的顺序依次介绍所有的选项，另外文末有“`print` 选项列表”方便查询。

`-l` 用于分行输出字符串：

```
# 每个字符串一行，字符串列表是用空格隔开的
% print -l aa bb
aa
bb

# 也可以接数组，数组相关的内容之后会讲到
# 命令后的多个字符串都可以用数组取代，效果是相同的
% array=(aa bb)
% print -l $array
aa
bb
```

`-n` 用于不在输出内容的末尾自动添加换行符（`echo` 命令也有这个用法）：

```
% print abc
abc
# 下面输出 abc 后的 % 高亮显示，代表这一行末尾没有换行符
% print -n abc
abc%
```

`-m` 用于只输出匹配到的字符串：

```
% print -m "aa*" aabb abc aac
aabb aac
```

`-o/-O/-i` 用于对字符串排序：

```
# print -o 对字符串升序排列
% print -o a d c 1 b g 3 s
1 3 a b c d g s

# print -O 对字符串降序排列
% print -O a d c 1 b g 3 s
s g d c b a 3 1

# 加 -i 参数后，对大小写不敏感
% print -oi A B C a c A B C
A a A B B C c C

# 不加 -i 的话小写排在大写的前面
% print -o A B C a c A B C
a A A B B c C C
```

`-r` 用于不对字符串进行转义。`print` 默认是会对转义字符进行转义的，加 `-r` 后会原样输出：

```
% print -r '\n'
\n
```

`-c` 用于将字符串按列输出。如果对自动决定的列数不满意，可以用 `-C` 指定列数：

```
% print -c a bbbbb ccc ddddd ee ffffff gg hhhhhh ii jj kk
a       ccc     ee      gg      ii      kk
bbbbb   ddddd   ffffff  hhhhhh  jj
```

`-C` 用于按指定列数输出字符串：

```
# 从上到下
% print -C 3 a bb ccc dddd ee f
a     ccc   ee
bb    dddd  f

% print -C 3 a bb ccc dddd ee f g
a     dddd  g
bb    ee
ccc   f

# 加 -a 后，改成从左向右
% print -a -C 3 a bb ccc dddd ee f g
a     bb    ccc
dddd  ee    f
g
```

`-D` 用于将符合条件的路径名转化成带 ~ 的格式（~ 是家目录）：

```
% print -D /home/goreliu/git
~/git

# mine 是这样定义的 hash -d mine='/mnt/c/mine'
% print -D /mnt/c/mine
~mine
```

`-N` 用于将输出的字符串以 `\x00`（null）分隔，而不是空格。这样可能方便处理包含空格的字符串，`xargs` 等命令也可以接受以 `\x00` 分隔的字符串：

```
% print -N aa bb cc
aabbcc%

% print -N aa bb cc | hexdump -C
00000000  61 61 00 62 62 00 63 63  00                       |aa.bb.cc.|
00000009
```

`-x` 用于将行首的 tab 替换成空格。`-x` 是将行首的 tab 展开成空格，`-x` 后的参数是一个 tab 对应的空格数：

```
% print -x 2 '\t\tabc' | hexdump -C
00000000  20 20 20 20 61 62 63 0a                           |    abc.|
00000008

% print -x 4 '\t\tabc' | hexdump -C
00000000  20 20 20 20 20 20 20 20  61 62 63 0a              |        abc.|
0000000c
```

`-X` 用于将所有的 tab 补全成空格。注意不是简单地替换成空格。比如每行有一个 tab，`-X 8`，那么如果 tab 前（到行首或者上一个 tab）有 5 个字符，就补全 3 个空格，凑够 8，这么做是为了对齐每一列的。但如果前边有 8 个或者 8 个以上字符，那么依然是一个 tab 替换成 8 个字符，因为 tab 不能凭空消失，一定要转成至少一个空格才行。如果没理解就自己多试试找规律吧。

```
% print -X 2 'ab\t\tabc' | hexdump -C
00000000  61 62 20 20 20 20 61 62  63 0a                    |ab    abc.|
0000000a

% print -X 4 'ab\t\tabc' | hexdump -C
00000000  61 62 20 20 20 20 20 20  61 62 63 0a              |ab      abc.|
0000000c
```

`-u` 用于指定文件描述符（fd）输出。`print` 默认输出到 fd 1，即 stdout，可以指定成其他 fd（2 是 stderr，其他的可以运行 `ls -l /proc/$$/fd` 查看。

```
% print -u 2 good
good

# 和重定向输出效果一样
% print good >&2
```

`-v` 用于把输出内容保存到变量：

```
# 和 str="$(print aa bb cc)" 效果一样
% print -v str aa bb cc
% echo $str
aa bb cc
```

`-s/-S` 用于把字符串保存到历史记录：

```
% print -s ls -a
% history | tail -n 1
 2222  ls -a

# -S 也类似，但需要用引号把命令引起来
% print -S "ls -a"
% history | tail -n 1
 2339  ls -a
```

`-z` 用于把字符串输出到命令行编辑区：

```
# _是光标位置
% print -z aa bb cc
% aa bb cc_
```

`-f` 用于按指定格式化字符串输出，同 `printf`，用法见“`printf` 命令用法”。

`-P` 用于输出带颜色和特殊样式的字符串，见“输出带颜色和特殊样式的字符串”。

`-b` 用于辨认出 bindkey 中的转义字符串，bindkey 是 Zle 的快捷键配置内容，写脚本用不到，不作介绍。

`-R` 用于模拟 `echo` 命令，只支持 `-n` 和 `-e` 选项，通常用不到。

### printf 命令用法

`printf` 命令很像 c 语言的 `printf` 函数，用于输出格式化后的字符串：

```
# 末尾输出高亮的 % 代表该行末尾没有换行符
# printf 不会在输出末尾自动添加换行符
# 为了避免误解，之后的例子省略该 % 符号
% printf ":%d %f:" 12 34.56
:12 34.560000:%
```

`printf` 的第一个参数是格式化字符串，在 zsh 里输入 `printf %` 后按 tab，可以看到所有支持的用法。下面只举几个比较常用的例子：

```
# 整数 浮点数 字符串
% printf "%d %f %s" 12 12.34 abcd
12 12.340000 abcd%

# 取小数点后 1 位
% printf "%.1f" 12.34
12.3

# 科学计数法输出浮点数
% printf "%e" 12.34
1.234000e+01

# 将十进制数字转成十六进制输出
% printf "%x" 12
c

# 补齐空格或者补齐 0
% printf "%5d\n%05d" 12 12
   12
00012
```

我把完整的格式贴在这里，方便搜索：

```
 -- print format specifier --
      -- leave one space in front of positive number from signed conversion
-     -- left adjust result
.     -- precision
'     -- thousand separators
*     -- field width in next argument
#     -- alternate form
%     -- a percent sign
+     -- always place sign before a number from signed conversion
0     -- zero pad to length
b     -- as %s but interpret escape sequences in argument
c     -- print the first character of the argument
E  e  -- double number in scientific notation
f     -- double number
G  g  -- double number as %f or %e depending on size
i  d  -- signed decimal number or with leading " numeric value of following character
n     -- store number of printed bytes in parameter specified by argument
o     -- unsigned octal number
q     -- as %s but shell quote result
s     -- print the argument as a string
u     -- unsigned decimal number
X  x  -- unsigned hexadecimal number, letters capitalized as x
```

### 输出带颜色和特殊样式的字符串

用 zsh 的 `print -P` 可以方便地输出带颜色和特殊样式的字符串，不用再和 `\033[41;36;1m` 之类莫名其妙的字符串打交道了。

```
# %B 加粗 %b 取消加粗
# %F{red} 前景色 %f 取消前景色
# %K{red} 背景色 %k 取消背景色
# %U 下滑线 %u 取消下滑线
# %S 反色 %s 取消反色
#
# black or 0  red     or 1
# green or 2  yellow  or 3
# blue  or 4  magenta or 5
# cyan  or 6  white   or 7

# 显示加粗的红色 abc
% print -P '%B%F{red}abc'
abc

# 没覆盖到的功能可以用原始的转义符号，可读性比较差
# 4[0-7] 背景色
# 3[0-7] 前景色
# 0m 正常 1m 加粗 2m 变灰 3m 斜体 4m 下滑钱 5m 闪烁 6m 快速闪烁 7m 反色

# 显示闪烁的红底绿字 abc
% print "\033[41;32;5mabc\033[0m"
abc
```

### print 选项列表

为了方便查询，我把 `print` 的选项列表放在这里：

| 选项   | 功能                        | 参数        |
| ---- | ------------------------- | --------- |
| -C   | 按列输出                      | 列数        |
| -D   | 替换路径成带 `~` 的版本            | 无         |
| -N   | 使用 `\x00` 作为字符串的间隔        | 无         |
| -O   | 降序排列                      | 无         |
| -P   | 输出颜色和特殊样式                 | 无         |
| -R   | 模拟 `echo` 命令              | 无         |
| -S   | 放命令放入历史命令文件（要加引号）         | 无         |
| -X   | 替换所有 tab 为空格              | tab 对应空格数 |
| -a   | 和 `-c`/`-C` 一起使用时，改为从左到右  | 无         |
| -b   | 识别出 bindkey 转义字符串         | 无         |
| -c   | 按列输出（自动决定列数）              | 无         |
| -f   | 同 `printf`                | 无         |
| -i   | 和 `-o`/`-O` 一起用时，大小写不敏感排序 | 无         |
| -l   | 使用换行符作为字符串分隔符             | 无         |
| -m   | 只输出匹配的字符串                 | 匹配模式字符串   |
| -n   | 不自动添加最后的换行符               | 无         |
| -o   | 升序排列                      | 无         |
| -r   | 不处理转义字符                   | 无         |
| -s   | 放命令放入历史命令文件（不加引号）         | 无         |
| -u   | 指定 fd 输出                  | fd 号      |
| -v   | 把内容保存到变量                  | 变量名       |
| -x   | 替换行首的 tab 为空格             | tab 对应空格数 |
| -z   | 把内容放置到命令行编辑区              | 无         |

### 参考

http://zsh.sourceforge.net/Guide/zshguide05.html
