### 导读

哈希表是比数组更复杂的数据结构，在某些语言里被称作关联数组或者字典等等。简单说，哈希表用于存放指定键（key）对应的值（value），键和值的关系，就像字典中单词和释义的对应关系，通过单词可以快速找到释义，而不需要从头依次遍历匹配。准确地说，哈希表只是该功能的一种实现方式，也可以使用各种树或者其他数据结构来实现，不同的实现方式适合不同的场景，使用方法是一样的。但为了简化概念，统一使用哈希表这个名称。

### 哈希表定义

和其他变量类型不同，哈希表是需要提前声明的，因为哈希表的赋值语法和数组一样，如果不声明，是无法区分的。

```zsh
% typeset -A table
# 或者用 local，二者功能是一样的
% local -A table

# 赋值的语法和数组一样，但顺序依次是键、值、键、值
% table=(k1 v1 k2 v2)

# 直接用 echo 只能输出值
% echo $table
v1 v2

# 使用 (kv) 同时输出键和值，(kv) 会把键和值都放到同一个数组里
% echo ${(kv)table}
k1 v1 k2 v2

# 哈希表的大小是键值对的数量
% echo $#table
2
```

### 元素读写

读写哈希表的方法和数组类似，只是用于定位的数字变成了字符串。

```zsh
# 可以声明和赋值写到一行
% local -A table=(k1 v1 k2 v2 k3 v3)
% echo $table[k2]
v2

% table[k2]="V2"

# 删除元素的方法和数组不同，引号不能省略
% unset "table[k1]"
% echo ${(kv)table}
k2 V2 k3 v3
```

### 哈希表拼接

```zsh
# 追加元素的方法和数组一样
% table+=(k4 v4 k5 v5)
% echo $table
V2 v3 v4 v5


% local -A table1 table2
% table1=(k1 v1 k2 v2)
% table2=(k2 v222 k3 v3)

# 拼接哈希表，要展开成数组再追加
% table1+=(${(kv)table2})
# 如果键重复，会直接替换值，哈希表的键是不重复的
% echo ${(kv)table1}
k1 v1 k2 v222 k3 v3
```

### 哈希表遍历

用 `(kv)` `(k)` 等先将哈希表转化成数组，然后再遍历。

```zsh
% local -A table=(k1 v1 k2 v2 k3 v3)

# 只遍历值
% for i ($table) {
> echo $i
> }
v1
v2
v3

# 只遍历键
% for i (${(k)table}) {
> echo $i
> }
k1
k2
k3

# 同时遍历键和值
% for k v (${(kv)table}) {
> echo "$k -> $v"
> }
k1 -> v1
k2 -> v2
k3 -> v3
```

### 元素查找

判断键是否存在。

```zsh
% local -A table=(k1 v1 k2 v2 k3 v3)
% (($+table[k1])) && echo good
good
% (($+table[k4])) && echo good
```

如果需要判断某个值是否存在，直接对值的数组判断即可。但这样做就体现不出哈希表的优势了。

```zsh
% local -A table=(k1 v1 k2 v2 k3 v3)
# value 是值的数组，也可以用 local -a 强行声明为数组
% value=($table)

% (( $value[(I)v1] )) && echo good
good
% (( $value[(I)v4] )) && echo good
```

### 元素排序

对哈希表元素排序的方法，和数组类似，多了 `k` `v` 两个选项，其余的选项如 `o`（升序）、`O`（降序）、`n`（按数字大小）、`i`（忽略大小写）等通用，不再一一举例。

```zsh
% local -A table=(aa 33 cc 11 bb 22)

# 只对值排序
% echo ${(o)table}
11 22 33

# 只对键排序
% echo ${(ok)table}
aa bb cc

# 键值放在一起排序
% echo ${(okv)table}
11 22 33 aa bb cc
```

### 从字符串、文件构造哈希表

因为哈希表可以从数组构造，所以从字符串、文件构造哈希表，和数组的操作是一样的，不再一一举例。

```zsh
% str="k1 v1 k2 v2 k3 v3"
% local -A table=(${=str})
% echo $table
v1 v2 v3
```

### 对哈希表中的每个元素统一处理

对哈希表中的每个元素统一处理，和对数组的操作是类似的，多了 `k` `v` 两个选项用于指定是对键处理还是对值处理，可以一起处理。不再一一举例。

```zsh
% local -A table=(k1 v1 k2 v2 k3 v3)
% print ${(U)table}
V1 V2 V3

% print ${(Uk)table}
K1 K2 K3

% print ${(Ukv)table}
K1 V1 K2 V2 K3 V3
```

`:#` 也可以在哈希表上用。

```zsh
% local -A table=(k1 v1 k2 v2 k3 v3)

# 排除匹配到的值
% echo ${table:#v1}
v2 v3

# 只输出匹配到的键
% echo ${(Mk)table:#k[1-2]}
k1 k2
```

### 多维哈希表

Zsh 并不支持多维哈希表以及多维数组，但可以通过一些方法来模拟，以实现一部分功能。

#### 用一维哈希表模拟多维哈希表

```zsh
% local -A table
# 这里用 , 作为分隔符，也可以用其他符号。
% table[1,1]=a
% table[1,2]=b
% table[k,v]=c
% echo $table[1,1] $table[1,2] $table[k,v]
a b c
```

好处：使用方便，而且支持的维数不受限制。

坏处：功能太单一，比如不能对 `table[1]` 进行处理。

#### 用字符串分割访问来模拟多维哈希表

```zsh
% local -A table
# 分隔符为空格
% table[1]='a b'
% table[2]='c d'
% print -l $table[1] ${table[1][(w)2]} ${table[2][(w)1]}
a b
b
c

# 分隔符不是空格
% table[a]='aa,bb'
% table[b]='cc,dd'
% print -l $table[a] ${table[a][(ws:,:)2]} ${table[b][(ws:,:)1]}
aa,bb
bb
cc
```

好处：可以对 `table[1]` 进行处理。

坏处：不大方便，性能也不好。而且功能同样受限，比如第一维只能是数组，不能是哈希表。可以支持更多维，但需要再增加新的分隔符，使用起来更麻烦。

### 总结

本篇简单讲了哈希表的基本用法。篇幅不长，但因为哈希表的操作和数组类似，很多操作数组的方法都可以用作哈希表上，而且可以把键或者值单独作为数组处理，所以操作哈希表更为复杂一些。

另外还有一些更进阶的处理数组和哈希表方法，之后会讲到。
