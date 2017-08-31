### 导读

alias（别名）在 shell 中是非常常用的，它主要用于给命令起别名，简化输入。但主要用于交互场景，在脚本中基本用不到。eval 是一个非常强大的命令，它的功能是将字符串解析成代码再执行，但也会额外增加很多复杂性，非必要场景尽量少用。alias 和 eval 看起来好像没什么关系，但功能上有相似之处，所以放在一起讲。

### alias

最典型的例子是将 ls -l 简化成 ll：

```
% alias ll='ls -l'
% ll
total 0
drwx------ 0 goreliu goreliu 512 Aug 31 13:55 tmux-1000
drwxr-xr-x 0 goreliu goreliu 512 Aug 31 13:37 yaourt-tmp-goreliu
```

alias 的效果相当于直接将字符串替换过来，比较好理解。

```
# 直接运行 alias，会列出所有的 alias
% alias
ll='ls -l'
lla='ls -F --color --time-style=long-iso -lA'
...
```

这样的 alias 只有在行首出现时，才会被解析。但 zsh 中还有一种功能更强大的全局 alias，不在行首也能被解析：

```
% alias -g G='| grep'

% ls G tmux
tmux-1000
```

但这样需要格外注意可能导致的副作用，比如我想创建一个名为 G 的文件：

```
% touch G
touch: missing file operand
Try 'touch --help' for more information.
Usage: grep [OPTION]... PATTERN [FILE]...
Try 'grep --help' for more information.
```

结果 G 被替换了，只能在 G 两边加引号。

如果全局 alias 没用好，可能导致灾难性的后果，比如误删重要文件（像把某个全局 alias 传给 rm 后，恰好删除了 alias 字符串中的某些文件），所以需要执行权衡后再使用，并且用的时候要多加注意。

### eval

eval 的功能是将字符串作为代码来执行。看上去好像很简单，但实际涉及很复杂的内容，主要是符号转义导致的语义问题。

在 bash 中，eval 的一个重要的使用场景是将变量的值当变量名，然后取它的变量值，类似于 c 语言中指向变量的指针：

```
% str1=str2
% str2=abc
% eval echo \$$str1
abc
```

注意这里有一个 \ 和两个 $，原因是第二个 $ 是和平时一样，正常取 str1 的值的，而第一个 $ 需要转义，因为它要在 eval 执行的过程中取 str2 的值，不能现在就展开。

这个用法很容易出问题，而且可读性很差。幸好 zsh 中无需这么用，有更好的办法：

```
% str1=str2
% str2=abc
% echo ${(P)str1}
abc
```

(P) 专门用于这种场景，不需要再去转义 $。

此外 eval 有时也用来动态执行代码，比如一个脚本接受用户的输入，而这输入也是一段脚本代码，就可以用 eval 来运行它。但这种用法是极其危险的，因为脚本中可能有各种危险操作，而且 shell 的语法很灵活，很难通过静态扫描的方法判断是否有危险操作。不可靠的代码根本不应该去运行。即使一定要运行，也可以先写到文件里再运行，避免传过来的代码影响到自身的逻辑。

但也不是说 zsh 中就完全没有必要用 eval 了，在某些特别的场景（比如用于改造语法加语法糖）还是有用的。但如果要使用，就一定要注意它可能导致的副作用，利弊只能自己权衡了。eval 的具体用法，和 bash 中的基本没有区别，可以去网上搜索 bash eval 用法来了解，这里就不介绍了。

### 总结

本文简单介绍了 alias 的用法和 eval 的场景使用场景。alias 很简单，主要在 .zshrc 里使用。eval 很复杂，非必要场景尽量避免使用。
