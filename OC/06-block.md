# block

#### block底层数据结构

- block本质上也是一个OC对象，它内部含有isa指针

- block是封装了函数调用以及函数调用环境的OC对象

- block底层结构：

  ```objective-c
  // 例如这样的一个block
  int age = 10;
  void(^block)(void) = ^{
  	NSLog(@"age is %d",age);
  }
  
  // 底层结构是
  // 包含三部分：block的内部实现，block的描述信息，引用(捕捉的)成员信息
  struct __main_block_impl_0 {
  	struct __block_impl impl; // block的内部实现信息
      struct __main_block_desc_0 *Desc; // block的描述信息
  	int age; // 引用的属性列表
  }
  
  // block的实现部分
  struct __block_impl {
      void *isa; // isa指针
      int Flags;
      int Reserved;
      void *FuncPtr; // 方法地址，用例调用block封装的方法
  }
  
  // block的描述信息，注意，如果block捕捉的属性是对象信息，那这里会有block对对象的引用函数(即是强引用还是弱引用，以及如何进行内存管理)
  struc __main_block_desc_0 {
      size_t reserved;
      size_t Block_size; // block的大小
  }
  ```

- **block的类型**

  block有3种类型，可以通过调用class方法或者isa指针查看具体类型，最终都是继承自NSBlock类型

  - __NSGlobalBlock__（NSConcreteGlobalBlock）：数据区域
  - __NSStackBlock__（NSConcreteStackBlock）：栈区
  - __NSMallocBlock__（NSConcreteMallocBlock）：堆区

  应用程序的内存分配：程序区域（.text）、数据区域（.data）、堆、栈

  **block类型的转变**：

  - 没有访问auto变量——>NSGlobalBlock
  - 访问了auto变量——>NSStackBlock
  - NSStackBlock调用了copy——>NSMallockBlock

  **每一种block调用copy后**

  | Block类型      | 副本源的配置存储域 | copy后的效果 |
  | -------------- | ------------------ | ------------ |
  | NSGlobalBlock  | 程序的数据区       | 什么也不做   |
  | NSStackBlock   | 栈区               | 从栈复制到堆 |
  | NSMallockBlock | 堆区               | 引用计数加一 |

- **MRC下block属性建议写法：**

  ```objective-c
  @property(copy, nonatomic) void(^block)(void);
  ```

  即用属性修饰词```copy```而不用```strong```。

  因为用了```copy```会将block从栈区复制到堆区进行操作，防止获取错误信息。如果block在栈区，且引用的auto成员变量也在栈区，系统会自动销毁收回成员变量，这时候再访问就容易获取错误信息，而复制到堆上就不会，堆上的信息需要程序员自己销毁。

- **ARC环境下的block:**

  - 建议写法：

    ```objective-c
    // 以下两中写法都可以，但为了同步MRC，建议用copy
    @property (strong, nonatomic) void (^block)(void);
    @property (copy, nonatomic) void (^block)(void);
    ```

  - 编译器会根据以下情况自动将栈上的block复制到堆上

    - block作为函数返回值时

    - 将block赋值给__strong指针时，即强引用时

    - block作为Cocoa API中方法名含有usingBlock的方法参数时

    - block作为GCD API的方法参数时

- **block引用对象类型的auto变量**

  - 如果block在栈上，将不会对auto变量产生强引用

  - 如果block被拷贝到堆上：

    会调用block内部的copy函数，copy函数内部会调用```_Block_object_assign```函数，```_Block_object_assign```函数会根据auto变量的修饰符(**__strong __weak __unsafe_unretained**)作出相应的操作，形成强引用或弱引用

  - block从堆上移除：

    会调用block内部的dispose函数，dispose函数内部会调用```_Block_object_dispose```，```_Block_object_dispose```函数会自动释放引用的auto变量

- **__block修饰符**

  - __block可以解决block内部无法修改auto变量的问题

  - __block不能修饰全局变量、静态变量（static）

  - block在栈上时，并不会对__block变量产生强引用

  - 内部原理：

    编译器会将__block变量包装成一个对象，然后进行操作

    ```objective-c
    // 简单的block
    __block int age = 10;
    ^{
    	NSLog(@"age is %d", age);
    }()
    
    // 编译器编译后的block对象，将age包装成了__Block_byref_age_0的对象
    struct __main_block_impl_0 {
    	struct __block_impl impl;
        struct __main_block_desc_0 *Desc;
        __Block_byref_age_0 *age; // by ref
    }
    
    // __Block_byref_age_0：age包装后的对象
    struct __Block_byref_age_0 {
        void *isa;
        __Block_byref_age_0 *__forwarding; // 指向自己的指针
        int __flags;
        int __size;
        int age; // 使用的值，真实值
    }
    ```

    内部修改block变量：拿到block对象的age，找到age中的__forwarding，再通过forwarding找到变量包装后的对象来修改里面的变量值：age->__forwarding->age = XXX.

    **注意：**当block被复制到堆上时，栈上的block里面的__forwarding指针指向堆上的block对象


#### block的循环引用

- 用__weak

  ```objective-c
  __weak typeof(self)weakSelf = self;
  self.block = ^{
  	printf("%p",weakSelf);
  }
  ```

- 用__unsafe_unretained解决

  ```objective-c
  __unsafe_unretained id weakSelf = self;
  self.block = ^{
  	printf("%p",weakSelf);
  }
  ```

- 用__block解决（必须要调用block）

  ```objective-c
  __block id weakSelf = self;
  self.block = ^{
  	printf("%p",weakSelf);
      weakSelf = nil;
  }
  self.block();
  ```

- 注意：

建议用```__weak```而不建议用```__unsafe_unretained```，因为当引用用的对象释放时，如果用weak修饰的话，block中的指针会被设置成nil，而用__unsafe_unretained修饰的不会设置成nil，这样会导致野指针访问。



#### Tips

- **clang将oc转换成c\c++时，__weak问题解决**

  需要支持ARC、指定运行时系统版本

  ```shell
  xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc -fobjc-arc -fobjc-runtime=ios-8.0.0 main.m
  # 不加对比：
  xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc main.m
  ```
