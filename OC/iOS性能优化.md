# iOS性能优化

这篇性能优化主要从四个方面来谈：应用启动时间；页面刷新滚动流畅度；耗电量；安装包的大小

#### 1、 应用启动时间

这里的应用时间指，应用启动到显示第一个页面展示时的时间。

应用启动有冷启动和热启动，热启动是指应用在后台活着，然后再启动应用。这里只谈冷启动。

启动流程和启动优化请阅读另一篇文章 [**iOS应用启动及启动时间优化**](../OC/iOS应用启动及启动时间优化.md)



#### 2、页面刷新滚动流畅度

在优化流程度前需要先了解下iOS页面的成像过程。

**CPU**（Central Processing Unit，中央处理器）:

对象的创建和销毁、对象属性的调整、布局计算、文本的计算和排版、图片的格式转换和解码、图像的绘制（Core Graphics）

**GPU**（Graphics Processing Unit，图形处理器）：

纹理的渲染



**成像过程**：

CPU计算信息，GPU渲染信息到帧缓存区（iOS是双缓存机制，有前帧缓存、后帧缓存），视频控制器从帧缓存中读取信息显示到屏幕上。



**造成卡顿的原因**：

按照60FPS的刷帧率，每隔16ms就会有一次VSync信号，VSync信号来的时候就需要从帧缓存区中取缓存显示到屏幕上，如果每次VSync信号来的时候CPU和GPU没有处理好信息渲染到缓存区，那么就会从缓存中拿之前缓存的显示，就造成了丢帧，丢帧多了就会造成卡顿。



**解决卡顿的核心**

尽可能减少CPU、GPU资源消耗



- **优化CPU**

  - 尽量用轻量级的对象，比如用不到事件处理的地方，可以考虑使用CALayer取代UIView

  - 不要频繁地调用UIView的相关属性，比如frame、bounds、transform等属性，尽量减少不必要的修改

  - 尽量提前计算好布局，在有需要时一次性调整对应的属性，不要多次修改属性

  - Autolayout会比直接设置frame消耗更多的CPU资源

  - 图片的size最好刚好跟UIImageView的size保持一致

  - 控制一下线程的最大并发数量

  - 尽量把耗时的操作放到子线程

    - 文本处理（尺寸计算、绘制）

    - 图片处理（解码、绘制）

- **优化GPU**

  - 尽量避免短时间内大量图片的显示，尽可能将多张图片合成一张进行显示

  - 尽量减少视图数量和层次

  - 减少透明的视图（alpha<1），不透明的就设置opaque为YES

  - 尽量避免出现离屏渲染

- **离屏渲染**

  在OpenGL中，GPU有2种渲染方式：

  - On-Screen Rendering：当前屏幕渲染，在当前用于显示的屏幕缓冲区进行渲染操作；

  - Off-Screen Rendering：离屏渲染，在当前屏幕缓冲区以外新开辟一个缓冲区进行渲染操作

  离屏渲染消耗性能的原因

  - 需要创建新的缓冲区
  - 离屏渲染的整个过程，需要多次切换上下文环境，先是从当前屏幕（On-Screen）切换到离屏（Off-Screen）；等到离屏渲染结束以后，将离屏缓冲区的渲染结果显示到屏幕上，又需要将上下文环境从离屏切换到当前屏幕

  会造成离屏渲染的有：

  - 光栅化，layer.shouldRasterize = YES
  - 遮罩，layer.mask
  - 圆角，同时设置layer.masksToBounds = YES、layer.cornerRadius大于（考虑通过CoreGraphics绘制裁剪圆角，或者叫美工提供圆角图片）
  - 阴影，layer.shadowXXX，如果设置了layer.shadowPath就不会产生离屏渲染



- **卡顿检测**

  平时所说的“卡顿”主要是因为在主线程执行了比较耗时的操作，这里检测的有两个方案：

  - Instruments中的coreAnimation工具，查看刷帧率，最理想最高的是60fps

  - 可以添加Observer到主线程RunLoop中，通过监听RunLoop状态切换的耗时，以达到监控卡顿的目的

    这个可以借助第三方框架（github上很多），如：[**LXDAppFluecyMonitor**](https://github.com/UIControl/LXDAppFluecyMonitor)、[**JPFPSStatus**](https://github.com/joggerplus/JPFPSStatus)



#### 3、耗电量

- 应用耗电的主要来源有：
  - CPU处理，Processing
  - 网络，Networking
  - 定位，Location
  - 图像，Graphics

- 耗电优化：
  - 尽可能降低CPU、GPU功耗

  - 少用定时器

  - 优化I/O操作

    - 尽量不要频繁写入小数据，最好批量一次性写入

    - 读写大量重要数据时，考虑用dispatch_io，其提供了基于GCD的异步操作文件I/O的API。用dispatch_io系统会优化磁盘访问
    - 数据量比较大的，建议使用数据库（比如SQLite、CoreData）

  - 网络优化

    - 减少、压缩网络数据
    - 如果多次请求的结果是相同的，尽量使用缓存
    - 使用断点续传，否则网络不稳定时可能多次传输相同的内容
    - 网络不可用时，不要尝试执行网络请求
    - 让用户可以取消长时间运行或者速度很慢的网络操作，设置合适的超时时间
    - 批量传输，比如，下载视频流时，不要传输很小的数据包，直接下载整个文件或者一大块一大块地下载。如果下载广告，一次性多下载一些，然后再慢慢展示。如果下载电子邮件，一次下载多封，不要一封一封地下载

  - 定位优化

    - 如果只是需要快速确定用户位置，最好用CLLocationManager的requestLocation方法。定位完成后，会自动让定位硬件断电
    - 如果不是导航应用，尽量不要实时更新位置，定位完毕就关掉定位服务
    - 尽量降低定位精度，比如尽量不要使用精度最高的kCLLocationAccuracyBest
    - 需要后台定位时，尽量设置pausesLocationUpdatesAutomatically为YES，如果用户不太可能移动的时候系统会自动暂停位置更新
    - 尽量不要使用startMonitoringSignificantLocationChanges，优先考虑startMonitoringForRegion:

  - 硬件检测优化

    - 用户移动、摇晃、倾斜设备时，会产生动作(motion)事件，这些事件由加速度计、陀螺仪、磁力计等硬件检测。在不需要检测的场合，应该及时关闭这些硬件



#### 安装包瘦身

安装包（IPA）主要由可执行文件、资源组成

- 资源（图片、音频、视频等）
  - 采取无损压缩
  - 去除没有用到的资源
- 可执行文件瘦身
  - 编译器优化
    - Strip Linked Product、Make Strings Read-Only、Symbols Hidden by Default设置为YES
    - 去掉异常支持，Enable C++ Exceptions、Enable Objective-C Exceptions设置为NO， Other C Flags添加-fno-exceptions
  - 利用AppCode（<https://www.jetbrains.com/objc/>）检测未使用的代码：菜单栏 -> Code -> Inspect Code
  - 编写LLVM插件检测出重复代码、未被调用的代码
  - 生成LinkMap文件，可以查看可执行文件的具体组成，哪些文件偏大
    - 可借助第三方工具解析LinkMap文件： <https://github.com/huanxsd/LinkMap>