# Class底层结构

#### Class的结构

```c
// 类的结构体信息
struct objc_class {
    Class isa; // 内部信息参考下面的**isa**
    Class superclass;
    cache_t cache; // 方法缓存
    class_data_bits_t bits; // 用于获取具体的类信息
}

// class_data_bits_t bits 经过位运算&FAST_DATA_MASK可获得以下数据
struct class_rw_t {
    uint32_t flags;
    uint32_t versions;
    const class_ro_t *ro; 		// 类的原始信息
    methon_list_t *methods; 	//方法列表，二维数组
    property_list_t *properties;// 属性列表
    const protocol_list_t *protocols; //属性列表
    Class fiestSubclass;
    Class nextSiblingClass;
    char *demangledName;
}

// 类的原始信息
struct class_ro_t {
    uint32_t flags;
    uint32_t instanceStart;
    uint32_t instanceSize; // instance对象占用多少存储空间
 #ifdef __LP64__
    uint32_t reserved;
 #endif
    const uint8_t *ivarLayout;
    const char * name; // 类名
    method_list_t *baseMethodList;
    protocol_list_t *baseProtocols;
    const ivar_list_t *ivars; // 成员变量列表
    const uint8_t *wearIvarLayout;
    property_list_t *baseProperties;
}


// 方法结构体
struct method_t {
    SEL name; // 函数名
    const char *types; // 编码(返回值、参数类型)
    IMP imp; // 指向函数的指针(函数地址)
}

typedef id _Nullable (*IMP) (id _Nonnull, SEL _Nonnull, ...);
typedef struct objc_selector *SEL;
```

- class_rw_t里面的methods、properties、protocols是二维数组，是可读可写的，包含了类的初始内容、分类的内容
- class_ro_t里面的baseMethodList、baseProtocols、ivars、baseProperties是一维数组，是只读的，包含了类的初始内容
- method_t是对方法\函数的封装（在methods中）
  - IMP代表函数的具体实现
  - SEL代表方法\函数名，一般叫做选择器，底层结构跟char *类似
    - 可以通过@selector()和sel_registerName()获得
    - 可以通过sel_getName()和NSStringFromSelector()转成字符串
    - 不同类中相同名字的方法，所对应的方法选择器是相同的
  - types包含了函数返回值、参数编码的字符串



#### 方法缓存

Class内部结构中有个方法缓存（cache_t），用**散列表（哈希表）**来缓存曾经调用过的方法，可以提高方法的查找速度

```c
struct cache_t {
    struct bucket_t *_buckets; // 散列表
    mask_t _mask; // 散列表长度-1
    mask_t _occupied; // 已经缓存的方法数量
}

struct bucket_t {
    cache_key_t _key; // SEL作为key，在查找时，也就是拿SEL来进行查找
    IMP _imp; // 函数的内存地址
}
```



**散列表查找说明：**

- 拿空间换时间

- 散列表中的每个元素都有一个key和要查询的值value
- 散列表存储：
  - 先开辟一定大小的存储空间给散列表，如一开始给开辟4个单元的大小，设定需要与之计算的mask（一般是散列表长度-1，因为列表重0开始计算，3）
  - 存储方法```test()```时，用类似于```@selector(test)&mask```计算方法，获取一个```index```下标，用这个```index```下标找到散列表中的位置，如果为空，就将```test()```方法包装成元素（key，vaule）放置在此位置中，将缓存数量加1
  - 如果根据```index```找到的位置不为空，取出对应位置的值，比较两个值的key是否相同，如果相同就不在进行缓存，如果不相同然后将```index```加1进行下标下移，直到找到空位子为止
  - 如果缓存的数量即将等于或大于散列表的长度，会将散列表的历史元素清除，然后再将散列值的大小扩大至两倍
- 散列表取值：
  - 根据元素特定的值与散列表的mask值进行计算，得出```index```下标值
  - 根据下标值找到对应位置的元素，比较元素中的key值，如果key值相同，则取出里面的值



#### isa

每一个实例对象或者类对象的底层都有isa指针，在arm64之前，isa只是一个普通的指针，指着它的类或者元类；在arm64之后，对isa进行了优化，变成了一个共用体（union）结构，并使用位域来存储更多的信息

arm64之后，isa是一个共用体了

```objective-c
union isa_t {
    Class cls; // 存储着类的地址
    unitptr_t bits; // 利用位域存储更多的信息
    struct {
        unitptr_t nonpointer			: 1; // 0代表普通指针，存储着class或meta-class,1代码优化过的，使用位域存储更多的信息
        unitptr_t has_assoc				: 1; // 是否有设置关联对象，如果没有，释放时会更快
        unitptr_t has_cxx_dtor			: 1; // 是否有c++的析构函数
        unitptr_t shiftcls				: 3; // 存储着Class、Meta-Class对象的内存地址信息
        unitptr_t magic					: 6; // 用于在调试时分辨对象是否未完成初始化
        unitptr_t weakly_referenced		: 1; // 是否有被弱引用指向过，如果没有，释放时会更快
        unitptr_t deallocating			: 1; // 对象是否正在释放
        unitptr_t has_sidetable_rc		: 1; // 引用计数器是否过大无法存储在isa中,如果为1，那么引用计数会存储在一个叫SideTable的类的属性中
        unitpyr_t extra_rc				: 1; // 里面存储的值是引用计数器减1
    }
}
```

