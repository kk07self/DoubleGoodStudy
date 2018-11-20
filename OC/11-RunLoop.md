# RunLoop

#### 简介

运行循环，在程序运行过程中循环做些事情

- 作用
  - 保持程序的持续运行
  - 处理APP中的各种事务（比如触摸事件、定时器）
  - 节省CPU，提高性能：该做事时做事，该休息时休息



#### RunLoop与线程

- 每条线程都有唯一的一个与之对应的RunLoop对象
- RunLoop保存在一个全局的Dictionary里，线程作为key，RunLoop作为value
- 线程刚创建时并没有RunLoop对象，RunLoop会在第一次获取它时创建
- RunLoop会在线程结束时销毁
- 主线程的RunLoop已经自动获取（创建），子线程默认没有开启RunLoop



#### RunLoop对象

NSRunLoop是对CFRunLoopRef的面相对象的封装

- **获取对象**

  - Foundation：

    ```objective-c
    [NSRunLoop currentRunLoop]; // 获得当前线程的RunLoop对象
    [NSRunLoop mainRunLoop]; // 获得主线程的RunLoop对象
    ```

  - Core Foundation

    ```objective-c
    CFRunLoopGetCurrent(); // 获得当前线程的RunLoop对象
    CFRunLoopGetMain(); // 获得主线程的RunLoop对象
    ```

- **Runloop相关的类**

  Core Foundation中有关于RunLoop有5个类

  - CFRunLoopRef：RunLoop类
  - CFRunLoopModeRef: RunLoop对应的模式类
  - CFRunLoopSourceRef：资源类
  - CFRunLoopTimerRef：事件类
  - CFRunLoopObserverRef：观察者类

  ```c
  typedef struct __CFRunLoop *CFRunLoopRef;
  struct __CFRunLoop {
  
      pthread_t _pthread;
      CFMutableSetRef _commonModes;
      CFMutableSetRef _commonModeItems;
      CFRunLoopModeRef _curentMode;
      CFMutableSetRef _modes;
  };
  
  typedef struct __CFRunLoopMode *CFRunLoopModeRef; 
  struct __CFRunLoopMode {
  
      CFStringRef _name;// 名称
      CFMutableSetRef _sources0;
      CFMutableSetRef _sources1;
      CFRunLoopModeRef _observers;
      CFRunLoopModeRef _times;
  };
  ```

  - **CFRunLoopModeRef**

    - CFRunLoopModeRef代表RunLoop的运行模式；

    - 一个RunLoop包含若干个Mode，每个Mode又包含若干个Source0/Source1/Timer/Observer；

    - RunLoop启动时只能选择其中一个Mode，作为currentMode；

    - 如果需要切换Mode，只能退出当前Loop，再重新选择一个Mode进入；

      不同组的Source0/Source1/Timer/Observer能分隔开来，互不影响；

      source1是捕捉事件的，source0是用来处理事件的

    - 如果Mode里没有任何Source0/Source1/Timer/Observer，RunLoop会立马退出

    - 常见的mode模式有两种：

      - kCFRunLoopDefaultMode（NSDefaultRunLoopMode）：App的默认Mode，通常主线程是在这个Mode下运行
      - UITrackingRunLoopMode：界面跟踪 Mode，用于 ScrollView 追踪触摸滑动，保证界面滑动时不受其他 Mode 影响
      - kCFRunLoopCommonModes：不是一种单独的模式，只是上面两个状态的集合

  - **CFRunLoopObserverRef**

    观察者主要是监听runloop的活跃状态

    ```objective-c
    /* Run Loop Observer Activities */
    typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
        kCFRunLoopEntry = (1UL << 0), 			// 即将进入runloop
        kCFRunLoopBeforeTimers = (1UL << 1),	// 即将处理timer
        kCFRunLoopBeforeSources = (1UL << 2),	// 即将处理sources
        kCFRunLoopBeforeWaiting = (1UL << 5),	// 即将进入休眠
        kCFRunLoopAfterWaiting = (1UL << 6),	// 即将从休眠中唤醒
        kCFRunLoopExit = (1UL << 7),			// 即将推出runloop
        kCFRunLoopAllActivities = 0x0FFFFFFFU
    };
    ```

    ```c
    // 监听不同的模式
    void observeRunLoopActicities(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
    {
        switch (activity) {
            case kCFRunLoopEntry:
                NSLog(@"kCFRunLoopEntry");
                break;
            case kCFRunLoopBeforeTimers:
                NSLog(@"kCFRunLoopBeforeTimers");
                break;
            case kCFRunLoopBeforeSources:
                NSLog(@"kCFRunLoopBeforeSources");
                break;
            case kCFRunLoopBeforeWaiting:
                NSLog(@"kCFRunLoopBeforeWaiting");
                break;
            case kCFRunLoopAfterWaiting:
                NSLog(@"kCFRunLoopAfterWaiting");
                break;
            case kCFRunLoopExit:
                NSLog(@"kCFRunLoopExit");
                break;
            default:
                break;
        }
    }
    ```




#### Runloop运行逻辑

- 01、通知Observers：即将进入loop
- 02、通知Observers：即将处理Timer，然后处理Timer
- 03、通知Observers：即将处理Sources，然后出来Sources
- 04、处理Blocks
- 05、处理Sources0（可能会再次处理blocks）
- 06、如果存在source1(有事件捕捉)则调到第08步
- 07、通知Observers：开始休眠（等待消息唤醒）
- 08、通知Observers：结束休眠（被某个消息唤醒）
  - 01>处理timer
  - 02>处理GCD
  - 03>处理Source1
- 09、处理blocks
- 10、根据前面执行结果，决定如何操作
  - 01>回到第02步，循环操作
  - 02>退出Loop
- 11、通知Observers：退出loop



- 休眠的实现原理：

  用户态中的```mach_msg()```让其进入到内核态进行休眠

  - 没有消息就让线程休眠
  - 有消息就进行唤醒，然后到用户态处理消息





#### RunLoop的应用

- 控制线程生命周期（线程保活）
- 解决NSTimer在滑动时停止工作的问题
- 监控应用卡顿
- 性能优化

