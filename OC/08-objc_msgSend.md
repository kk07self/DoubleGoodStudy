# objc_msgSend-消息机制

OC中方法的调用，其实都是转为objc_msgSend()函数的调用

Objc_msgSend()函数的执行分为三个阶段

- 消息发送阶段
- 动态方法解析阶段
- 消息转发阶段



#### 流程1：消息发送阶段

- 消息接收者receiver是否为nil，如果receiver为nil直接退出
- 从receiver的Class的cache中查找方法，找到了就调用方法查找结束
- 从receiver的Class的class_rw_t中查找方法，找到了就调用方法并将其缓存在Class的cache_t中，结束查找
- 判断上层是否有superClass，如果有则继续以下查找，往复，如果没有就进行到下一阶段（动态方法解析）
- 从receiver的superClass得cache中查找方法，找到了就调用方法查找结束
- 从receiver的superClass的class_rw_t方法列表中查找方法，找到了就调用方法并将其缓存在Class的cache_t中，结束查找



#### 流程2：动态方法解析

- 是否曾经有动态解析，如果有，则进入到下一阶段（消息转发阶段）
- 如果没有，调用```+resolveInstanceMethod\-resolveInstanceMethod```方法来动态解析方法
- 将动态解析的方法放到class_method_t中，并标记为已经动态解析过了，然后走流程1消息发送阶段

开发者可以实现以下方法，来动态添加方法实现

- +resolveInstanceMethod:

- +resolveClassMethod:

动态解析过后，会重新走“消息发送”的流程，“从receiverClass的cache中查找方法”这一步开始执行

**动态添加方法**

```objective-c
void c_other(id self, SEL _cmd)
{
    NSLog(@"c_other - %@ - %@", self, NSStringFromSelector(_cmd));
}

+ (BOOL)resolveClassMethod:(SEL)sel
{
    if (sel == @selector(test)) {
        // 第一个参数是object_getClass(self)
        class_addMethod(object_getClass(self), sel, (IMP)c_other, "v16@0:8");
        return YES;
    }
    return [super resolveClassMethod:sel];
}

+ (BOOL)resolveInstanceMethod:(SEL)sel
{
    if (sel == @selector(test)) {
        // 动态添加test方法的实现
        class_addMethod(self, sel, (IMP)c_other, "v16@0:8");

        // 返回YES代表有动态添加方法
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}
```



**流程3：消息转发**

- 调用forwardingTargetForSelector：方法，如果返回值不为nil，则向返回值发送消息objc_msgSend(返回值，方法)
- 如果返回值为nil，则调用methodSignatureForSelector:方法，返回值不为nil，则调用forwardInvocation:方法
- 如果返回值为nil，则调用doesNotRecognizeSelector：方法

开发者可以在forwardInvocation:方法中自定义任何逻辑

以上方法都有对象方法、类方法2个版本（前面可以是加号+，也可以是减号-）

```objective-c
@implementation MJPerson

+ (id)forwardingTargetForSelector:(SEL)aSelector
{
    // objc_msgSend([[MJCat alloc] init], @selector(test))
    // [[[MJCat alloc] init] test]
    if (aSelector == @selector(test)) return [[MJCat alloc] init];

    return [super forwardingTargetForSelector:aSelector];
}

//+ (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
//{
//    if (aSelector == @selector(test)) return [NSMethodSignature signatureWithObjCTypes:"v@:"];
//    
//    return [super methodSignatureForSelector:aSelector];
//}
//
//+ (void)forwardInvocation:(NSInvocation *)anInvocation
//{
//    NSLog(@"1123");
//}

@end
    
+ (void)test
{
    NSLog(@"%s", __func__);
}

- (void)test
{
    NSLog(@"%s", __func__);
}
```

