

# runtime API

#### 类

```c
// 动态创建一个类（参数：父类，类名，额外的内存空间）
Class objc_allocateClassPair(Class superclass, const char *name, size_t extraBytes);

// 注册一个类（要在类注册之前添加成员变量）
void objc_registerClassPair(Class cls);

// 销毁一个类
void objc_disposeClassPair(Class cls);

// 获取isa指向的Class
Class object_getClass(id obj);

// 设置isa指向的Class
Class object_setClass(id obj, Class cls);

// 判断一个OC对象是否为Class
BOOL object_isClass(id obj);

// 判断一个Class是否为元类
BOOL class_isMetaClass(Class cls);

// 获取父类
Class class_getSuperclass(Class cls);
```



#### 成员变量 

```c
// 获取一个实例变量信息
Ivar class_getInstanceVariable(Class cls, const char *name);

// 拷贝实例变量列表（最后需要调用free释放）
Ivar *class_copyIvarList(Class cls, unsigned int *outCount);

// 设置和获取成员变量的值
void object_setIvar(id obj, Ivar ivar, id value);
id object_getIvar(id obj, Ivar ivar);

// 动态添加成员变量（已经注册的类是不能动态添加成员变量的）
BOOL class_addIvar(Class cls, const char * name, size_t size, uint8_t alignment, const char * types);

// 获取成员变量的相关信息
const char *ivar_getName(Ivar v);
const char *ivar_getTypeEncoding(Ivar v);


// 成员变量的数量
unsigned int count;
Ivar *ivars = class_copyIvarList([MJPerson class], &count);
for (int i = 0; i < count; i++) {
    // 取出i位置的成员变量
    Ivar ivar = ivars[i];
    NSLog(@"%s %s", ivar_getName(ivar), ivar_getTypeEncoding(ivar));
}
free(ivars);


// 获取成员变量信息
Ivar ageIvar = class_getInstanceVariable([MJPerson class], "_age");
NSLog(@"%s %s", ivar_getName(ageIvar), ivar_getTypeEncoding(ageIvar));

// 设置和获取成员变量的值
Ivar nameIvar = class_getInstanceVariable([MJPerson class], "_name");

MJPerson *person = [[MJPerson alloc] init];
object_setIvar(person, nameIvar, @"123");
object_setIvar(person, ageIvar, (__bridge id)(void *)10);
NSLog(@"%@ %d", person.name, person.age);
```



#### 属性 

```c
// 获取一个属性
objc_property_t class_getProperty(Class cls, const char *name);

// 拷贝属性列表（最后需要调用free释放）
objc_property_t *class_copyPropertyList(Class cls, unsigned int *outCount);

// 动态添加属性
BOOL class_addProperty(Class cls, const char *name, const objc_property_attribute_t *attributes, unsigned int attributeCount);

// 动态替换属性
void class_replaceProperty(Class cls, const char *name, const objc_property_attribute_t *attributes, unsigned int attributeCount);

// 获取属性的一些信息
const char *property_getName(objc_property_t property);
const char *property_getAttributes(objc_property_t property);
```



#### 方法

```c
// 获得一个实例方法、类方法
Method class_getInstanceMethod(Class cls, SEL name);
Method class_getClassMethod(Class cls, SEL name);

// 方法实现相关操作
IMP class_getMethodImplementation(Class cls, SEL name);
IMP method_setImplementation(Method m, IMP imp);
void method_exchangeImplementations(Method m1, Method m2);

// 拷贝方法列表（最后需要调用free释放）
Method *class_copyMethodList(Class cls, unsigned int *outCount);

// 动态添加方法
BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types);

// 动态替换方法
IMP class_replaceMethod(Class cls, SEL name, IMP imp, const char *types);

// 获取方法的相关信息（带有copy的需要调用free去释放）
SEL method_getName(Method m);
IMP method_getImplementation(Method m);
const char *method_getTypeEncoding(Method m);
unsigned int method_getNumberOfArguments(Method m);
char *method_copyReturnType(Method m);
char *method_copyArgumentType(Method m, unsigned int index);

// 选择器相关
const char *sel_getName(SEL sel);
SEL sel_registerName(const char *str);

// 用block作为方法实现
IMP imp_implementationWithBlock(id block);
id imp_getBlock(IMP anImp);
BOOL imp_removeBlock(IMP anImp);


// 例
MJPerson *person = [[MJPerson alloc] init];   
Method runMethod = class_getInstanceMethod([MJPerson class], @selector(run));
Method testMethod = class_getInstanceMethod([MJPerson class], @selector(test));
method_exchangeImplementations(runMethod, testMethod);
[person run];


#import "UIControl+Extension.h"
#import <objc/runtime.h>

@implementation UIControl (Extension)

+ (void)load
{
    // hook：钩子函数
    Method method1 = class_getInstanceMethod(self, @selector(sendAction:to:forEvent:));
    Method method2 = class_getInstanceMethod(self, @selector(kk_sendAction:to:forEvent:));
    method_exchangeImplementations(method1, method2);
}

- (void)kk_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event
{
    NSLog(@"%@-%@-%@", self, target, NSStringFromSelector(action));
    
    // 调用系统原来的实现
    [self kk_sendAction:action to:target forEvent:event];
    
//    [target performSelector:action];
    
//    if ([self isKindOfClass:[UIButton class]]) {
//        // 拦截了所有按钮的事件
//
//    }
}

@end



// 防止数组空元素及数组越界
#import "NSMutableArray+Extension.h"
#import <objc/runtime.h>

@implementation NSMutableArray (Extension)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 类簇：NSString、NSArray、NSDictionary，真实类型是其他类型
        Class cls = NSClassFromString(@"__NSArrayM");
        Method method1 = class_getInstanceMethod(cls, @selector(insertObject:atIndex:));
        Method method2 = class_getInstanceMethod(cls, @selector(kk_insertObject:atIndex:));
        method_exchangeImplementations(method1, method2);
    });
}

- (void)kk_insertObject:(id)anObject atIndex:(NSUInteger)index
{
    if (anObject == nil) return;
    
    [self kk_insertObject:anObject atIndex:index];
}

@end


// 防止字典空key
#import "NSMutableDictionary+Extension.h"
#import <objc/runtime.h>

@implementation NSMutableDictionary (Extension)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"__NSDictionaryM");
        Method method1 = class_getInstanceMethod(cls, @selector(setObject:forKeyedSubscript:));
        Method method2 = class_getInstanceMethod(cls, @selector(kk_setObject:forKeyedSubscript:));
        method_exchangeImplementations(method1, method2);
        
        Class cls2 = NSClassFromString(@"__NSDictionaryI");
        Method method3 = class_getInstanceMethod(cls2, @selector(objectForKeyedSubscript:));
        Method method4 = class_getInstanceMethod(cls2, @selector(kk_objectForKeyedSubscript:));
        method_exchangeImplementations(method3, method4);
    });
}

- (void)kk_setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key
{
    if (!key) return;
    
    [self kk_setObject:obj forKeyedSubscript:key];
}

- (id)kk_objectForKeyedSubscript:(id)key
{
    if (!key) return nil;
    
    return [self kk_objectForKeyedSubscript:key];
}

@end


#import "NSArray+Extension.h"
#import <objc/runtime.h>

@implementation NSArray (Extension)
+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 类簇：NSString、NSArray、NSDictionary，真实类型是其他类型
        Class cls = NSClassFromString(@"__NSArrayI");
        Method method1 = class_getInstanceMethod(cls, @selector(objectAtIndex:));
        Method method2 = class_getInstanceMethod(cls, @selector(kk_objectAtIndex:));
        method_exchangeImplementations(method1, method2);
    });
}

- (id)kk_objectAtIndex:(NSUInteger)index {
    if (index >= self.count) {
        return nil;
    }
    return [self kk_objectAtIndex:index];
}

@end
```

