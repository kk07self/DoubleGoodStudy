# KVC

KVC的全称是Key-Value Coding，俗称“键值编码”，可以通过一个key来访问某个属性.

#### API

- 常见API

  - -(void)setValue:(id)value forKeyPath:(NSString *)keyPath;
  - -(void)setValue:(id)value forKey:(NSString *)key;
  - -(id)valueForKeyPath:(NSString *)keyPath;
  - -(id)valueForKey:(NSString *)key; 

- forKey与forKeyPath的区别

  - forkey：访问其直接属性

  - forKeyPath：访问直接属性或间接属性，可根据属性路径一层一层访问下去

    例如：

    ```objective-c
    @interface Cat : NSObject
    @property (assign, nonatomic) int weight;
    @end
    
    @interface Person : NSObject
    @property (assign, nonatomic) int age;
    
    @property (assign, nonatomic) Cat *cat;
    @end
        
    // 这里通过kvc访问person下面的cat对象里面的weight，使用forKey是不行的，需要使用forKeyPath, forKeyPay:@"cat.weight",这样一层一层路径关联下去就可以访问到
    ```


#### setVaule: forKey: 原理

当调用此方法时：

- 先查找```setKey:```方法，如果没有查找```_setKey:```方法，如果找到了，传递参数调用方法
- 如果上面两个set方法都没找到，查看```accessInstanceVariablesDirectly```方法的返回值（默认是YES）
- 如果上个步骤返回为NO，则调用```setValue:forUndefinedKey:```并抛出异常```NSUnknownKeyException```
- 如果上个步骤的返回值是YES，按照```_key、_isKey、key、isKey```的顺序查找成员变量，找到成员变量进行复制，找不到抛出异常



#### valueForKey:的原理

当调用此方法时：

- 按照```getKey、key、isKey、_key```顺序查找get方法，找到了，调用方法返回值
- 若以上都没有找到，则调用```accessInstanceVariablesDirectly```方法，查看其返回值
- 如果上一步返回时NO,则调用```setValue:forUndefinedKey:```并抛出异常```NSUnknownKeyException```
- 如果上个步骤的返回值是YES，按照```_key、_isKey、key、isKey```的顺序查找成员变量，找到成员变量取值返回，找不到抛出异常