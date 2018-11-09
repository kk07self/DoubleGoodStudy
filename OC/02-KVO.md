# KVO

Key-Value Observing

#### 实现原理

- 利用runtime API动态生成一个子类，并让实例对象的isa指针，从原来的类指向这个子类
- 这个子类会重写监听属性的set方法，在set方法中完成对属性修改的监听，调用监听的方法
- 这个子类的superclass属性指向其父类，方便调用不需要重写的方法，比如属性的get方法
- 实现流程：
  - 修改实例对象的属性值时，会通过isa指针找到新的子类
  - 在新的子类中找到其对应的属性set方法
  - 在set方法中会调用Foundation的c语言函数（_NSSetXXXValueAndNotify），这个函数会实现属性的赋值、监听器的触发
    - _NSSetXXXValueAndNotify()函数中会调用：willChangeValueForKey:方法
    - 调用父类的set方法，让其属性完成赋值
    - 再调用didChangeValueForKey：方法，这个方法内部会触发监听器的监听方法
- 其他：
  - 会重写class方法：返回原始类，让开发者忽略子类的存在，隐藏kvo的内部实现
  - 会重写delloc方法：需要在销毁时做些额外处理
  - 会重新_isKVOA方法

#### 其他

- 手动触发KVO：手动调用willChangeValueForKey:方法，didChangeValueForKey:方法

- 直接修改成员变量会不会触发KVO：不会触发，因为没有调用其属性的set方法
