

# NSObject本质

#### 1 Objective-C的底层实现是：C/C++实现的

OC—————>C/C++—————>汇编语言—————>机器语言

将OC代码转换成C/C++代码：

```sh
xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc 源文件 -o 输出的cpp文件
```

如果需要链接到其他框架，使用 ```-framework```参数



#### 2 OC的对象、类：基于C/C++的结构体实现

例： NSObject

```objective-c
// oc语言
@interface NSObject {
	Class isa;
}
@end

// c/c++
struct NSObject_IMPL {
	Class isa;
}

typedef struct object_class *Class;// 对象指针
```

例：student

```objective-c
// oc
@interface Student: NSObject {
    @public
	int _age;
    int _no;
}
@end
    
// c/c**
struct Student_IMPL {
    struct NSObject_IMPL NSObject_IVAR;
    int _age;
    int _no;
}

// 由于 struct NSObject_IMPL结构体中只有一个isa指针，因此可以简写成
struct Student_IMPL {
	Class isa;
    int _age;
    int _no;
}

// 可以检验下：
Student *stu = [[Student alloc] init];
stu->_age = 4;
stu->_no = 5;

// 可以将stu对象转换成结构体

struct Student_IMPL stu_impl = (__ bridge struct Student_IMPL)stu;
stu_impl->_age, stu_impl_no；// 这里获取的信息和stu获取的信息一样
```

列：Person、Student

```objective-c
// OC
@interface Person: NSObject {
	int _age;
}
@end

@interface Student: Person {
	int _no;
}
@end

// C/C++
struct Person_IMPL {
	struct NSObject_IMPL NSObject_IVAR;
    int _age;
}

struct Student_IMPL {
	struct Person_IMPL Person_IVAR;
    int _no;
}
```





#### 3 一个NSObject对象内存分配16个字节的地址：

内存分配了16个地址，即占用了16个字节的地址，但实际上只使用了8个字节的地址，isa指针使用的。

获取实例对象的内存大小：

```objective-c
#import <objc/runtime.h>
class_getInstanceSize([NSObject class]); // 获取的是对象在内存中真正使用了多少内存

#import <malloc/malloc.h>
malloc_size((__bridge const void *)obj); // 获取的是对象在内存中实际被分配了多少内存
```

**补充：**

- 内存对齐，结构体内存的大小必须是最大成员变量大小的倍数

- 系统内存分配对齐，内存在给数据类型进行存储空间分配时，也是要对齐的，即16的倍数（iOS系统中，会提前准备好内存块，有16、32、48、64...最大256，在分配时会从这里拿一块去给与）


#### 4 OC对象的分类

- **实例对象**：

  通过类alloc出来的对象，每次调用alloc都会产生新的实例对象

  实例对象内存储的信息包括：

  - isa指针

  - 其他成员变量

- **类对象**

  每一个类对象在内存中只有一个class对象

  类对象在内存中的存储信息主要包括：

  - isa指针
  - superclass指针
  - 类的属性信息（@property）
  - 类的对象方法（instance method）
  - 类的协议信息（protocol）
  - 类的成员变量信息（ivar）
  - ·······

  ```objective-c
  NSObject *bj = [[NSObject alloc] init]; // bj实例对象
  Class obClass1 = [bj class]; // 类对象
  Class obClass2 = [NSObject class];// 类对象
  Class obClass3 = object_getClass(bj);// 类对象 runtime API
  Class metaClass1 = object_getClass(obClass3); // 元类对象，runtime API
  Class obClass4 = [[NSObject class] class]; // 获取的还是类对象
  // 获取元类对象只有用runtime的api进行获取
  Class metaClass2 = object_getClass([NSObject class]);
  
  // 判断某个类对象是不是元类对象
  # import <objc/runtime.h>
  BOOL result = class_isMetaClass([NSObject class]);
  ```

- **元类对象**

  每一个类在内存中有且只有一个元类对象（meta-class）

  元类对象在内存中的存储信息包括：

  - isa指针

  - superclass指针

  - 类的类方法信息（class method）

  - ······


#### 5 isa SuperClass

- **isa指针**：

  - 实例对象的isa指针指向类（class）

    当调用实例对象的对象方法时，通过isa指针找到class，然后找到里面的对象方法

  - Class 的isa指针指向meta-class（元类）

    当调用类方法是，通过isa指针找到meta-class，然后从其中找到类方法

- **superClass：**

  类对象、元类对象才有superClass指针

  - 对象方法调用时

    先通过对象的isa指针，找到其class，查看其class中是否有对应的对象方法，如果有就调用其对象方法，如果没有，通过类的superclass指针找到其父类并查看其是否有对应的对象方法，以此类推，直到找到基类，如果基类也没有，就抛出方法找不到异常。

  - 类方法调用时

    先通过类对象的isa指针，找到其元类对象meta-class，查看其class中是否有对应的类方法，如果有就实现，如果没有，就通过meta-class的superclass指针找到其父类并查看其是否有对应的类方法，以此类推，直到基类元类，如果基类元类也没有，再通过基类元类的suerclass指针找到基类，查看其对象方法中有没有同名的对象方法，如果有就调用对象方法；如果到这一步还没有，就抛出方法找不到异常。

- **备注**：
  - isa指针指向的并不是类的地址，而是需要位运算下才能得到真正需要指向的地址，@ ISA_MASK
  - superclass指向的就是其父类的地址