### 导读

我们已经了解了字符串、数组、哈希表、整数、浮点数的基本用法，但应付某些复杂的场景依然力不从心。

变量修饰语是 zsh 中有一个很独特的概念，对变量进行操作，功能上和函数类似，但用起来更方便，在一行代码里实现复杂功能主要靠它了。而代价是可读性更差，怎么用就要自己权衡了。它也是 zsh 最有特色的部分之一。变量修饰语主要应用于数组和哈希表，但也有一小部分可以应用于字符串（整数和浮点数也会被当成字符串处理）。

### 变量修饰语的格式

其实前边的文章中，变量修饰语已经出现过，但当时没有详细说明。

比如在大小写转换的例子中。

```
% str="ABCDE abcde"

# 转成大写，(U) 和 :u 两种用法效果一样
% echo ${(U)str} --- ${str:u}
ABCDE ABCDE --- ABCDE ABCDE

# 转成小写，(L) 和 :l 两种用法效果一样
% echo ${(L)str} --- ${str:l}
abcde abcde --- abcde abcde
```

这里的 `(U)`、`:l` 等等都是变量修饰语。变量修饰语主要有两种格式。

```
${(x)var}
${var:x}
```

其中 var 是变量名，x 是 一个或多个字母，不同字母的功能不同。第二行的冒号也可能是其他符号。${var} 和 $var 基本相同，大括号用于避免变量名中的字符和后边的字符粘连，通常情况是不需要加大括号的。但如果使用变量修饰语，大括号就必不可少（其实第二种格式中，大括号可以省略，但考虑可读性和错误提示等因素，还是加上比较好）。

变量修饰语可以嵌套使用。因为加了修饰语的变量依然是变量，可以和正常的变量一样处理。

```
% str=abc
% echo ${(U)str}
ABC
% echo ${(C)${(U)str}}
Abc

% echo ${${a:u}:l}
abc

# 可以两种风格嵌套在一起
% echo ${(C)${a:u}}
Abc
```

这里要注意 $ 之后全程不能有空格，否则会有语法错误。也就是说不能通过加空格来避免因为字符挤在一起造成的可读性变差。但熟悉了格式后，就可以比较容易识别出代码的功能。比较复杂的逻辑可以换行继续写，而没必要一定嵌套使用。

知道了变量修饰语的用法后，重要的就是都有哪些可以使用的变量修饰语了。

### 变量默认值

和变量默认值（读取变量时如果变量为空或者不存在，使用的默认值）相关的操作，变量可以是任何类型的。

```
% var=123

# 如果变量有值，就输出变量值
% echo ${var:-abc}
123

# 如果变量没有值（变量不存在，为空字符串、空数组、空哈希表等），输出 abc
% echo ${varr:-abc}
abc


% var=""
# 和 :- 类似，但只有变量不存在时才替换成默认值
% echo ${var-abc}
% echo ${varr-abc}
abc


% var=""
# 和 :- 类似，但如果变量没有值，则赋值为 abc
% echo ${var:=abc}
abc
% echo $var
abc


% var=abc
# 不管 var 有没有值，都赋值为 123
% echo ${var::=123}
123
% echo $var
123


% var=""
# 如果 var 没有值，直接报错
% echo ${var:?error}
zsh: var: error


% var=abc
# 如果 var 有值，输出 123
% echo ${var:+123}
% echo ${varr:+123}

```

### 数组拼接成字符串

```
% array=(aa bb cc dd)

# 用换行符拼接
% echo ${(F)array}
aa
bb
cc
dd

# 用空格拼接
% str=$array
% echo $str
aa bb cc dd

# 使用其他字符或字符串拼接
% echo ${(j:-=:)array}
aa-=bb-=cc-=dd
```

### 字符串切分成数组

```
% str=a##b##c##d

% array=(${(s:##:)str})
% print -l $array
a
b
c
d
```

### 输出变量类型

```
# 注意如果不加 integer 或者 float，都为字符串，但计算时会自动转换类型
% integer i=1
% float f=1.2
% str=abc
% array=(a b c)
% local -A hashmap=(k1 v1 k2 v2)

% echo ${(t)i} ${(t)f} ${(t)str} ${(t)array} ${(t)hashmap}
integer float scalar array association
```

### 字符串、数组或哈希表嵌套取值

可以嵌套多层。

```
% str=abcde
% echo ${${str[3,5]}[3]}
e

% array=(aa bb cc dd)
% echo ${${array[2,3]}[2]}
cc
# 如果只剩一个元素了，就取字符串的字符
% echo ${${array[2]}[2]}
b

% local -A hashmap=(k1 v1 k2 v2 k3 v3)
% echo ${${hashmap[k1]}[2]}
1
```

### 字符串内容作为变量名再取值

不需要再通过繁琐的 eval 来做这个。

```
% var=abc
% abc=123

% echo ${(P)var}
123
```

### 对齐或截断数组中的字符串

```
% array=(abc bcde cdefg defghi)

# 只取每个字符串的最后两个字符
% echo ${(l:2:)array}
bc de fg hi

# 用空格补全字符串并且右对齐
% print -l ${(l:7:)array}
    abc
   bcde
  cdefg
 defghi

# 用指定字符补全
% print -l ${(l:7::0:)array}
0000abc
000bcde
00cdefg
0defghi

# 用指定字符补全，第二个字符只用一次
% print -l ${(l:7::0::1:)array}
0001abc
001bcde
01cdefg
1defghi

# 左对齐
% print -l ${(r:7::0::1:)array}
abc1000
bcde100
cdefg10
defghi1
```

### 总结

文中只介绍了几个比较常用的变量修饰语，还有一些没有提及，可能后续再补充。

### 参考

http://www.bash2zsh.com/zsh_refcard/refcard.pdf
