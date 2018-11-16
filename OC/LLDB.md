# LLDB

#### 指令的格式是

```objective-c
<command> [<subcommand> [<subcommand>...]] <action> [-options [option-
value]] [argument [argument...]]
```

- 命令名称：<command>
- 子命令：[<subcommand> [<subcommand>...]]
- 命令操作：<action>
- 命令选项：[-options [option- value]]
- 命令参数：[argument [argument...]]

例如：给某个函数设置断点

```c
breakpoint set -n test // 给test函数设置断点，breakpoint-命令名称，set-命令操作，-n-命令选项， test-参数
```



#### 常用指令

- **0-help指令**

  查看指令

  - **help**：可查看所有lldb命令

  - **help 命令**：可查看此命令下所有的操作或子命令，如```help breakpoint```即可查到```breakpoint```下的所有子命令或操作（set write read name...）

  - **help 命令 子命令（操作）**：可查询子命令或操作下的命令选项，如```help breakpoint set```即可查出```set```下的命令选项(-n -t -s...)

- **1-打印指令**

  - **p、po**：

    p 和 po 的区别在于使用 po 只会输出对应的值，而 p 则会返回值的类型以及命令结果的引用名。

    p还可以进行常量的进制转换

    ```objective-c
    //默认打印为10进制
    (lldb) p 100
    (int) $8 = 100
    //转16进制
    (lldb) p/x 100
    (int) $9 = 0x00000064
    //转8进制
    (lldb) p/o 100
    (int) $10 = 0144
    //转二进制
    (lldb) p/t 100
    (int) $2 = 0b00000000000000000000000001100100
    //字符转10进制数字
    (lldb) p/d 'A'
    (char) $7 = 65
    //10进制数字转字符
    (lldb) p/c 66
    (int) $10 = B\0\0\0
    
    ```

  - **expression**

    执⾏一个表达式，修改参数值

    expression cmd-option -- expr

    - cmd-option：是一个命令选项

    - --：是结束前面命令选项的标识

    - expr：是指表达式

    - 通常可以直接省略中间的命令选项```expression expr```

      ```objective-c
      expression self.view.backgroundColor = [UIColor redColor]; // 动态设置背景颜色
      ```

  - **call**

    在断点调用某个方法，并输出此方法的返回值。

    注意，这里只能调用没有参数的方法或函数。

    ```objective-c
    (lldb) call test
    (int (*)()) $0 = 0x0000000100000d70 (C`test at main.c:34)
    (lldb) call test();
    -------test----------
    (int) $1 = 2
    (lldb) 
    ```

- **2-Thread**

  - **thread backtrace或bt**

    打印线程的堆栈信息

  - **thread return**

    跳出当前方法的执行

  - **流程控制**

    ```objective-c
    继续：continue, c
    下一步：next, n
    进入：step, s
    跳出：finish, f
    ```

  - **frame select N**

    bt打印出了堆栈信息列表，如果想看指定的位置，可以使用```frame select n```

  - **frame variable**

    查看帧变量，打印当前帧的变量

- **3-Image**

  - **image lookup -address 查找崩溃位置**

    当你遇见数组崩溃，你又没有找到崩溃的位置，只扔给你一堆报错信息，这时候image lookup来帮助你

  - **image lookup -name 查找方法来源**

    此命令可以用来查找方法的来源。包括在第三方SDK中的方法，也能被查到。

    ```objective-c
    image lookup -n test // test是方法
    ```

  - **image lookup –type 查看成员**

    查看某个class的所有属性和成员变量。不过貌似frameWork库中文件不能查看

    ```objective-c
    image lookup -t Student // Student是类
    ```

- **4-breakpoint**

  - **给某一行加断点**

    ```breakpoint set -f xxx -l xxx
    breakpoint set -f xxx -l xxx // -f后面跟文件名，-l后跟行数
    breakpoint set -f Student.m -l 5 // 给Student.m文件的第5行加断点
    ```

  - **给函数加断点**

    ```objective-c
    breakpoint set -n 方法名
    breakpoint set -n viewDidLoad // 给viewDidLoad加断点
    ```

  - **查看断点列表**

    ```objective-c
    breakpoint list
    ```

  - **禁用、启用断点**

    ```breakpoint disable/enable 断点标识```

  - **移除断点**

    ```breakpoint delete 断点标识```

