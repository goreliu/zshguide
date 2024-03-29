### 导读

在正式的场景，代码写完后都是需要测试的，shell 脚本也不例外。但 shell 脚本的特性导致测试方法和其他语言有所不同。

### 单元测试

作为一种重要的测试方法，单元测试在很多种编程语言程序测试中起到举重轻重的作用。但不幸的是，单元测试基本不适用于 shell 脚本。并不是说 shell 脚本不能被单元测试，而是说单元测试能测试出来的问题很少，投入却很大。为了让 shell 脚本能被单元测试，50 行的代码很可能要改写成 100 多行甚至更多行。更重要的是 shell 脚本严重依赖外部环境，多数问题需要对脚本整体进行功能测试才能发现，而不是对单个函数进行单元测试。对单元测试的精力投入很可能会减少在功能测试的精力投入。

所以不建议推行 shell 脚本的单元测试，这不仅会让开发者很痛苦，也很难减少问题的出现几率，甚至有可能适得其反。

### 单个脚本的功能测试

Shell 脚本的最小测试粒度是单个脚本。必须保证单个脚本是容易测试的，不能多个脚本耦合太紧密而难以对其中某一个进行单独测试。

有主体逻辑的脚本依赖的外部环境必须是容易模拟的。比如需要从数据库中读取数据，对数据进行处理，然后写入到文件中，这些功能不能在同一个脚本中完成。因为数据库这个外部环境不容易模拟，会导致测试困难。需要把读写数据库的功能独立成单独的脚本，功能尽量简单，测试该脚本时只需要关心数据是否正常读取了出来，格式是否被正确转换等等，而不需要关心处理数据的具体逻辑。处理数据的主体逻辑代码要独立成一个（或者多个）脚本，测试该脚本时，无需准备数据库环境，直接用另一个脚本或者数据文件取代读取数据库的脚本，提供测试数据。如果文件写入的环境复杂（比如文件或者目录结构复杂，或者要写入到分布式文件系统等等），也需要将文件写入的脚本独立出来以便更易于测试。

对有主体逻辑的脚本进行功能测试，不能手动进行，必须写测试脚本，可以自动运行。每次脚本改动后进行回归测试。项目稳定后，可以在每次提交代码后自动运行测试脚本。测试脚本必须覆盖正常和异常情况，不能只覆盖正常情况。异常情况的多少，要根据脚本的复杂度而定。

有复杂外部依赖的脚本，功能必须单一，逻辑尽量简单，代码尽量稳定，不经常改动。比如读写数据库、启停进程、复杂的目录文件操作等有复杂外部依赖的脚本，功能必须单一，只与一个特定的外部依赖交互，提供尽量和外部依赖无关的中间数据，尽量不包含和外部环境无关的逻辑。该类脚本要容易模拟，以便在测试其他部分时不再需要依赖外部环境。

对于有复杂外部依赖的脚本，可以写脚本自动测试，也可以手动测试，测试时需要包含正常和异常的情况，不能只测试正常情况。

### 功能测试示例

**需要写脚本完成如下功能：**

如果 process1 和 process2 两个进程都存在，以 process2 进程 cwd 目录中的 `data/output.txt` 为输入，做一些比较复杂的处理，然后输出到 process1 进程 cwd 目录中的 `data/input.txt` 文件（如果该文件已存在，则不处理），处理完后，删除之前的 `data/output.txt`。

**分析：**

process1 和 process2 两个进程都是复杂的外部依赖，不能在主体逻辑脚本里直接依赖它们，所以要把检查进程是否存在的逻辑独立成单独的脚本。输入和输出文件的路径依赖进程路径，为了测试方便，也要把获取文件路径的逻辑独立成单独的脚本。

**脚本功能实现：**

检查进程是否存在和获取进程 cwd 目录的 util.zsh 脚本：

```zsh
#!/bin/zsh

check_process() {
    pidof $1
}

get_process_cwd() {
    readlink /proc/$1/cwd
}
```

主体逻辑脚本 main.zsh：

```zsh
#!/bin/zsh

# 有错误即退出，可以省掉很多错误处理的代码
set -e

# 切换到脚本当前目录
cd ${0:h}

# 加载依赖的脚本
source ./util.zsh

# 检查进程是否存在
local process1_pid=$(check_process process1)
local process2_pid=$(check_process process2)

# 这里的 input 和 output 是相对脚本来说的
local input_file=$(get_process_cwd $process2_pid)/data/output.txt
local output_file=$(get_process_cwd $process1_pid)/data/input.txt

# 如果输入文件不存在，直接退出
[[ -e $input_file ]] || {
    echo $input_file not found.
    exit 1
}

# 如果输出文件已存在，也直接退出
[[ -e $output_file ]] && {
    echo $output_file already exists.
    exit 0
}

# 处理 $input_file 内容
# 省略

# 将结果输出到 $output_file
# 省略
```

**功能测试方法：**

util.zsh 里的两个函数功能过于简单，无需测试。

测试 main.zsh 时，需要构造一系列测试用的 util.zsh，用于模拟各种情况：

```zsh
# 进程存在的情况
check_process() {
    echo $$
}

# 进程不存在的情况
check_process() {
    return 1
}

# 进程 process1 存在而 process2 不存在的情况
check_process() {
    [[ $1 == process1 ]] && echo 1234 && return
    [[ $1 == process2 ]] && return 1
}

# 输出了进程号，但实际进程不存在的情况
check_process() {
    echo 0
}

# 其他情况
# 省略


# 路径存在的情况
get_process_cwd() {
    [[ $1 == process1 ]] && echo /path/to/cwd1 && return
    [[ $1 == process2 ]] && echo /path/to/cwd2 && return
}

# 路径不存在的情况
get_process_cwd() {
    return 1
}

# 输出了路径，但路径实际不存在的情况
get_process_cwd() {
    echo /wrong/path
}

# 其他情况
# 省略
```

然后组合这些情况，写测试脚本判断 main.zsh 的处理是否符合预期。

其中一个测试脚本样例：

util_test1.zsh 内容：

```zsh
#!/bin/zsh

# 进程存在
check_process() {
    echo $$
}

# 直接返回正确的路径
get_process_cwd() {
    [[ $1 == process1 ]] && echo /path/to/cwd1 && return
    [[ $1 == process2 ]] && echo /path/to/cwd2 && return
}
```

test.zsh 内容：

```zsh
#!/bin/zsh

# 用于测试的函数，可以独立成单独脚本以便复用
assert_ok() {
    (($1 == 0)) || {
        echo Error, retcode: $1
        exit 1
    }
}

check_output_file() {
    # 检查输出文件是否符合预期
    # 省略
}

# 应用 util_test1.zsh
ln -sf util_test1.zsh util.zsh

# 运行脚本
./main.zsh

# 检查返回值是否正常
assert_ok $?

# 检查输出文件是否符合预期
check_output_file /path/to/output/file

# 其他检查
# 省略

# 应用 util_test2.zsh
ln -sf util_test2.zsh util.zsh

# 省略
```

### 集成测试

测试完每个脚本的功能后，需要将各个脚本以及其他程序整合起来测试互相调用过程是否正常。如果功能比较复杂，需要分批整合，测试各个逻辑单元是否能正常工作。在这部分测试中，和外部环境交互的脚本如果逻辑较为简单，可以不参与，用模拟脚本替代。可以手动测试或自动测试。同样不能只测试正常情况。

### 系统测试

将所有相关组件整合起来，测试整个系统或者子系统的功能。模拟脚本不能参与系统测试，必须使用真实的外部环境。系统测试通常需要手动进行，可以用自动化测试系统来辅助。需要覆盖尽可能多的情况，不能只测试系统的正常功能。

### 总结

本文简单介绍了 shell 脚本的测试方法，以及编写可测试代码的方法。
