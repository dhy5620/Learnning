# 1、内存

1、热更之前的加载场景大多直接使用了Resources的资源，在加载场景生命周期结束时应当调用Resources.UnloadUnusedAssets()来卸载资源

2、OL使用puerts+hybridclr来热更，其中puerts的gc依赖js的内存标记策略。然后Unity的mono也有自己的一套gc策略，虽然两者相同，但并不意味着两者会在同时gc。因此可以在unity主动发生gc环节主动调用puerts的gc（场景加载时），这样可以在切换场景时让不用的内存一定能释放掉。

3、puets和c#在沟通的过程中，引用对象是使用的同一块内存，但值类型会有装箱拆箱操作，因此会发生很多不必要的内存分配，可以使用puerts自带的blittablecopy功能，优化值类型的传递

4、OL项目存在大量log输出，线上版本应该避免

5、OL项目使用了大量的携程进行资源的加载等操作，更改为Unitask（值类型任务），减少gc

6、资源压缩：纹理存在大批未压缩的问题

# 2、CPU

## UI性能优化

### Canvas.SendWillRenderCanvases

1. 这里更新的是vertex 属性，比如 color、tangent、position、uv，修改recttransform的position、scale，rotation并不会导致顶点属性改变，因为顶点的position是根据pivot的偏移决定的，而改变其size、pivot、anchor，则会修改UI的transform属性，从而引发重建，还包括替换图片，更新文本等

2. 优化建议：隔帧更新


### Canvas.BuildBatch & EmitWorldScreenspaceCameraGeometry 

 网格重建包含了UI更新，比如recttransform位置的改变，虽然没有UI更新，但有网格重建

1. Canvas.BuildBatch:UI元素改变导致需要重新build mesh 时，主线程调用该函数发起网格合并。

2. 合并的过程在子线程中实现，如果网格过于复杂，出现了主线程的等待，则耗时会被统计到

EmitWorldScreenspaceCameraGeometry这个函数里面

3. unity 会把同一个canvas下的所有UI合并成一个mesh，根据层级的不同，分成多个submesh，所以尽可能合批，减少submesh，减少drawcall
4. 优化建议：增加合批、动静分离

### SyncTransform

对于UI元素调用SetActive（false改成true）会导致：

该Canvas下所有的同级UI元素触发SyncTransform，从而导致较高的耗时。

该Canvas的父Canvas下的同级UI元素触发SyncTransform

该UI元素同级的canvas下的UI元素不会触发SyncTransform

一句话：同级及父级下的UI元素，除了canvas 都会SyncTransform

优化建议：通过设置local scale=0/1来实现相同的效果

### EventSystem.Update

EventSystem组件主要负责处理输入、射线投射以及发送事件、UI的创建会自动创建相关组件处理UI点击事件。raycast target 不用就关闭它

### **UI DrawCall**

通常战斗场景中其他模块耗时压力大，此时UI模块更要仔细控制性能开销。一般而言，战斗场景中的UI DrawCall控制到40-50左右为最佳。

在制作过程中，建议关注以下几点：
（1）同一Canvas下的UI元素才能合批。不同Canvas即使Order in Layer相同也不合批，所以UI的合理规划和制作非常重要；
（2）尽量整合并制作图集，从而使得不同UI元素的材质图集一致。图集中的按钮、图标等需要使用图片的比较小的UI元素，完全可以整合并制作图集。当它们密集地同时出现时，就有效降低了DrawCall；
（3）在同一Canvas下、且材质和图集一致的前提下，避免层级穿插。笼统地说，应使得符合合批条件的UI元素的“层级深度”相同；
（4）将相关UI的Pos Z尽量统一设置为0。Z值不为0的UI元素只能与Hierarchy中相邻元素尝试合批，所以容易打断合批。
（5）对于Alpha为0的Image，需要勾选其CanvasRender组件上的Cull Transparent Mesh选项，否则依然会产生DrawCall且容易打断合批。

### UGUI的GC优化

UGUI的GC优化其他文章说的比较详细了，这里说一个比较容易忽视的一点，就是当Prefab中有大量空的Text，初始化的时候就会有很严重的GC Alloc。这是因为在初始化时，会先初始化TextGenerator，如果Text为空，则会先按50个字来初始化，即50个字的UI Vertex和50个字的UICharInfo，这种可以不让它为空，或者填一个空格进去来组织。

## Spine MultiRender

暂时没有特别好的方案，最好是美术进行优化。

OL大厅界面有一个spine耗时很高，此时打开其他界面，最好隐藏大厅或者关闭

引用：

[Unity 性能优化四：UI耗时函数、资源加载、卸载API_unity assetbundle loadallassets 耗时大-CSDN博客](https://blog.csdn.net/qq_37672438/article/details/131983127)

[Unity性能优化 — UI模块_emitorworldscreen-CSDN博客](https://blog.csdn.net/UWA4D/article/details/120132810)

# 3、GPU

1、当某个全屏UI打开时，建议将被背景遮挡住的其他UI进行关闭。

2、对于Alpha为0的UI，建议将其Canvas Renderer组件上的CullTransparent Mesh进行勾选，这样既能保证UI事件的响应，又不需要对其进行渲染。

![img](https://img-blog.csdnimg.cn/img_convert/186cdefef858a090d7bb0a3bf699d431.png)



3、尽可能减少Mask组件的使用，不仅提高绘制的开销，同时会造成DrawCall上升。在Overdraw较高的情况下，可以考虑使用RectMask2D代替。

4、在URP下需要额外关心是否有没必要的Copy Color或者Copy Depth存在。尤其是在UI和战斗场景中的相机使用同一个RendererPipelineAsset的情况下，容易出现不必要的渲染耗时和带宽浪费，这样会对GPU造成不必要的开销。通常建议UI相机和场景相机使用不同的RendererData。

# 4、资源压缩

## 纹理压缩：

  (1)颜色通道:RGB代表基本三原(基)色通道 A代表透明通道 RGBA32–每个通道占8bit RGBA16–每个通道占4bit ；

  (2)图片类型：.jpg–有损压缩不透明 .png–无损压缩有透明 ；

  (3)图片导入unity 由于GPU不识别图片格式(.png/.jpg) 导致无法直接解压 Unity3D引擎对纹理的处理是智能的 unity导入后不论你是.png/.hpg 都会被设置纹理格式 在不同手机GPU上若某个设置的纹理格式不被识别 unity会自动转换为RGBA32纹理格式—>这样导致贴图是无损无压缩 内存占用是最大的 所以必须设置正确的纹理格式 ；

  (4)纹理压缩格式的内存计算方式：
    menory=width * height*每像素对应的字节大小
    例如：以一张1024X1024的贴图为例 ---->1byte=8bit
     RGBA32 Bit：表示每个像素占用32bit 4byte，内存大小 = 1024 X 1024 X 4 = 4M
     RGBA16 Bit：表示每个像素占用16bit 2byte，内存大小 = 1024 X 1024 X 2= 2M
     RGB ETC1 4Bit： 表示每个像素占用4bit 0.5byte，内存大小 = 1024 X 1024 X 0.5= 0.5M
     RGBA ETC2 8Bit： 表示每个像素占用8bit 1byte，内存大小 = 1024 X 1024 X 1= 1M
     RGBA PVRTC 4Bit： 表示每个像素占用4bit 0.5byte，内存大小 = 1024 X 1024 X 0.5= 0.5M
     RGBA ASTC 4X4 block : 表示每个像素占用8bit 1byte，内存大小 = 1024 X 1024 X 1= 1M

​				   RGBA ASTC 6X6 block : 表示每个像素占用8bit 0.45byte，内存大小 = 1024 X 1024 X 0.45= 0.45M

     RGBA ASTC 8X8 block : 表示每个像素占用8bit 0.25byte，内存大小 = 1024 X 1024 X 0.25= 0.25M
     ASTC–特殊计算 1block–16byte 4X4=1block -->1像素=1byte 8X8=1block --> 1像素=0.25(16/64)byte ；

  (5)图片尺寸：
    ETC1(不支持透明通道)、ETC2(支持透明通道)以及ASTC 4X4 要求图片宽和高可以不相等但是必须被4整除
    PVRTC压缩格式要求图片的宽高必须相等并且是2的整数次幂，例如512X512，如果是512X1024那么就无法压缩了 ；

  (6)硬件限制：
    ETC2只支持OpenGL ES 3.0以上的Android手机（大概2013年以后的手机都支持,不用使用ETC1-不用通道分离）
    ASTC只支持苹果A8以后的设备，iPhone 6 及以上的手机（大概2014年以后的手机都支持） ；

  (7)Android 支持OpGL3.0使用RGBAEtc2.0 8 bits(支持透明通道)
    对于没有透明通道的Texture 使用 RGBEtc2 (ASTC大量手机不支持 2016年之后的安卓手机基本支持这种压缩格式) ；

  (8)IOS平台使用ASTC6*6 (不支持苹果5,iphone6以后都支持 支持透明通道)压缩率比PVRT4 bit 好 硬件限制弱 ；

  (9)对于背景图 必须是2的N次幂 这样才能压缩



引用：[unity 纹理压缩 内存优化_astc纹理大小计算-CSDN博客](https://blog.csdn.net/baidu_39447417/article/details/100643454)

[Unity性能优化 - 内存篇_unity里的图片内存太大-CSDN博客](https://blog.csdn.net/qq_33808037/article/details/107887953)

[纹理优化：让你的纹理也“瘦”下来 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/273388281)

## 音频压缩：

### 3D音效使用Force to Mono

立体声有左右两个声道，大小和内存占用都会翻倍。但是Unity中两个声道都是从同一个点发出，双声道没有意义

***最佳实践：\***
***如果使用了双声道的音源，可以通过勾选Force to Mono轻松将双声道音源变成普通音源，节省内存开支\***

### 关于压缩类型

- **Decompress on Load** – 解压完整的数据进内存
- **Compressed in Memory** – 加载进内存，使用的时候解压。用CPU性能换一部分内存。
- **Streaming** – 完全不加载进内存，使用时从存储介质中串流。最省内存，消耗最多CPU。

下图为同一声音文件在默认压缩格式下使用3种不同加载类型的CPU和内存消耗：

![img](https://pic1.zhimg.com/v2-89bddf1407e576517dc53d9f46238ac8_r.jpg)

### 关于压缩格式

在使用Decompress on Load时，压缩格式对内存没有影响（因为无论如何都是会解压后进内存的），但是对包体大小会有影响。使用PCM会增加包体大小，而使用Ogg Vorbis包体会更小，但是在加载进内存时需要解压缩，不过解压缩的消耗可以忽略不计。

在使用Compressed in Memory时，如果你想要通过Quality选项进一步压缩声音文件的质量和大小，使用Ogg Vorbis会更好。但是在同样100% Quality的情况下，ADPCM占用的内存比Ogg Vorbis更小，而且解压缩消耗的CPU资源比Ogg Vorbis小很多。不过，无论如何不要使用PCM，因为PCM是不压缩的格式，完全没有利用上Compressed in Memory的优势。

在使用Streaming时，和Compressed in Memory类似，使用ADPCM可以节省很多CPU资源。不同的是，可以使用PCM进一步节省CPU资源，因为PCM没有压缩。PCM唯一的缺点是会占用更多的存储资源。

MP3格式相较上述格式没有显著优势，因此不用考虑。

另外，需要注意的是，在移动端短时间内Stream多个声音文件可能会造成CPU的高负载。

> ***最佳实践：\***
> *–* ***时间短的音效使用Decompress on Load，压缩格式使用Ogg Vorbis\***
> *–* ***时间较长的音效使用Compressed in Memory，压缩格式使用ADPCM\***
> *–* ***音乐（如背景音）使用Streaming，压缩格式使用PCM\***

### 声音数量限制和优先级

Unity默认的声音数量限制是32个，但可以通过设置更改

Real Voice是指真正能听到的声音数量。假如限制为1，则无论什么时候都只能听到1个声音，其他声音会根据优先级依次变为Virtual Voice。

Virtual Voice会在后台继续播放，但实际听不到。当Real Voice小于设定的上限时，Virtual Voice会根据优先级变成Real Voice继续播放。如果Virtual Voice数量大于设置的上限时，会根据优先级被停止。

每个声音都可以设置优先级，0为最高，256为最低：

> ***最佳实践：\***
> *–* ***尽量保持默认设置。如果需要提高上限，手机上Max Real Voices最好低于40，高端手机低于60；主机、桌面端低于80。\***
> *–* ***Max Virtual Voices大于Max Real Voices\***
> *–* ***大部分声音都使用一样的优先级，少数重要的声音设置高优先级\***

### 暂停不使用的声音

如果Max Real Voices设置的不高，这个方法没有必要。如果设置了较高的声音数量上限，则有必要手动暂停一些在AudioListener以外的声音。只需要给所有带声音的物体挂上如下脚本即可：

### 非必须的音效勾选Load in Background

![img](https://pic4.zhimg.com/v2-df677e7a238ee8c23ec2d8f81493fbdf_r.jpg)

勾选此选项后，Unity在加载场景时不会等待该声音完全加载好，可以减少加载场景的时间。下图是在加载场景时加载约90个音频和大量Prefab时，勾选和不勾选Load in Background的对比。不是很精确的实验，但是有参考作用：

### 合理加载音频数据

![img](https://pic3.zhimg.com/v2-a44c168df2e19bfa12f6bfd3005c78ea_r.jpg)

Unity导入音频时有个默认勾选的选项为Preload Audio Data，即在加载声音文件时，同时将声音的信息（如时长）和音频数据加载进内存。如果不勾选，则只有声音信息会被加载进内存。

因此，如果不勾选此选项，可以节省一些内存，但是需要在使用该声音时手动加载：

```text
audioClip.LoadAudioData();
```

为了节省内存，也可以手动卸载该声音：

```text
audioClip.UnloadAudioData();
```

> ***最佳实践：\***
> ***手动卸载不需要使用的音频数据，在需要时重新加载\***

### 禁用音频组建而不是使用静音

当音频组件还被挂在物体上时，就算使用了静音，也依然存在相关的性能开销（如计算声音和Audio Listener）之间的距离。因此，如果不是真的有“静音”这个需求，尽量禁用音频组件，搭配上一段落的卸载音频数据效果更佳。

引用：[Unity音频优化实践 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/357031530)

[Unity 优化 音频 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/468733550)

## 动画资源

### Optimize Game Objects

Unity官方文档的解释是：
In the GameObjects hierarchy of a character, the GameObjects which only contain Transform [component](https://so.csdn.net/so/search?q=component&spm=1001.2101.3001.7020), will be optimized out unless they are specified in extraExposedTransformPaths for better CPU performance. The remaining GameObjects hierarchy will be flattened.

当勾选了该选项后，FBX中的骨骼节点，如果只有Transform组件，会被剔除不导入，
如果需要某些骨骼节点不被剔除，例如需要挂点，则需要在Extra Transform Paths中勾选对应的骨骼名称。
注意：不剔除的节点会被移到根节点之下，因此代码中不能通过原有路径查找（transform.Find(“Bip001/Bip001 Spine”)）。

原理：
Remove and store the GameObject Transform hierarchy of the imported character in the Avatar and Animator component. If enabled, the SkinnedMeshRenderers of the character use the Unity animation system’s internal skeleton, which improves the performance of the animated characters.
Only available if the Avatar Definition is set to Create From This Model.

Unity会将骨骼信息映射到avatar中，这样，unity在更新骨骼矩阵时，不再考虑场景中的Transform节点，也不用更新它的坐标，而是直接通过获取avatar骨骼信息来更新蒙皮，表现动画，从而节省了cpu计算。

### 精度过高的动画片段

如果动画文件的浮点精度很高，动画片段的表现效果一般来讲也会更好更细致，但是会在内存上带来额外的开销。而适当进行精度压缩，虽然表现效果上会有所降低，但考虑到动画片段的数量和帧数，由此带来的内存节省将会十分可观。

我们建议将精度缩减到3~4位，基于UWA长久以来的实际项目经验，动画片段的精度为3~4位时，能在对表现效果影响较小的情况下，有效降低内存上的开销。

### 使用了MotionVector的SkinnedMeshRenderer

Unity中，在Mesh Renderer与Skinned Mesh Renderer组件中都可以开启Motion Vector，用以获取物体的运动信息。若开启，相机会在渲染管线中增加一个motion vector pass，将运动向量渲染在一个Buffer当中，用户可以将Shader脚本中这个Buffer用于后处理特效。

Motion Vector一般会用于运动模糊这样的后处理特效、基于时间的抗锯齿算法（temporal antialiasing）等。但是Motion Vector带来的显存中的双倍buffer开销和运算量开销是不容忽视的。而Skinned Motion Vector在移动端项目当中的应用也是很少的，一般不建议开启。

所以，在本条规则筛选出对应的Skinned Mesh Renderer后，开发团队需要根据实际情况决定是否勾选对应骨骼动画的Skinned Motion Vector。

## 粒子

### 粒子数上限超过30的粒子系统

在粒子系统中，合理的粒子数会使得诸如火焰或者落叶等特效的表现效果恰到好处。而过多的粒子数不仅会造成内存上的大量占用，实际运行时也会给CPU和GPU的计算带来更大压力。

基于UWA工程师的经验总结和对业内大数据的统计分析，我们发现在一般情况下，粒子系统的粒子数上限不超过30，即可满足大部分情况下所需的粒子表现效果。

开发团队可以通过本条规则，依据实际的展示表现，为粒子系统设置合理的粒子数上限，在保留特效水平的前提下优化内存和运算开销。

![img](https://pic3.zhimg.com/v2-6cac76eaa7b0e70a3b976cccf746ff82_r.jpg)



### 引用纹理尺寸大于256的粒子系统

在粒子系统中，我们会需要引用纹理来为粒子“穿上衣服”，以此配合需要达成的各种特效展示效果。
针对单个粒子而言，纹理尺寸的增大，对于整体的粒子表现效果的提升可能并不会那么明显。UWA通过对行业大数据的分析发现：针对大部分粒子系统的使用，纹理尺寸达到256x256即可满足大部分的表现需求。

通过本条规则，大家可以过滤出那些引用纹理尺寸“偏大”的粒子系统，为那些展示效果变动不明显的粒子系统进行“瘦身”。既可以减轻内存和计算的压力，也能够空出宝贵的性能空间去用于那些更重要的粒子系统。

### 网格发射数超过5的粒子系统

粒子的渲染模式可分为两大类：2D的Billboard（公告牌）图形模式和Mesh模式。Billboard是3D游戏中用的非常多的一种技术，使用该模式，粒子会以一个平面的形式存在，并始终以一定的角度对着我们的镜头。举个例子来讲，场景中有一棵树，是实体存在的；但在各种Billboard模式下，你只需要看到这棵树的一个“面”。在展示效果上表现其实一样，但渲染一个“面”和渲染一整个实体，前者在消耗的内存和运算量上会更有优势。

而“Mesh”模式就是我们今天的主题。这个模式允许粒子系统发射3D网格而非2D的Billboard，以此来实现更为复杂和贴合需求的粒子效果。

3D网格性能开销显然是高于2D的Billboard的。如果粒子系统的发射的网格数量过大，会带来较高的CPU计算开销、GPU渲染压力甚至较高的堆内存分配。所以我们对使用Mesh进行渲染的粒子系统的“最大粒子数”要求更为严苛。一般的粒子系统中，粒子发射数上限建议不超过30（我们在之前的文章中有进行讨论，详见[《【性能黑榜】掌握了这些规则，你已经战胜了80%的对手！》](https://link.zhihu.com/?target=https%3A//blog.uwa4d.com/archives/UWA_Pipeline14.html)）。经由UWA的测试结果表明：渲染模式为Mesh、网格发射数在不超过5的情况下，能够维持粒子效果和性能消耗上的一个相对平衡。

所以开发团队在本条规则执行后，需要对筛选出来的粒子系统进行显示效果和性能消耗上的平衡考量，并对相应的粒子系统进行修改。

### 开启prewarm的粒子系统

在UWA报告的重要性能参数中我们可以留意到有个函数：ParticleSystem.Prewarm，表示当前帧有粒子系统开启了“Prewarm”选项，而开启该选项的粒子系统在场景中实例化或者由Deactive转为active时，会立即执行一次完整的模拟。以“火焰”为例，Prewarm开启时，加载后第一帧即能看到“大火”，而不是从“火苗”开始逐渐变大。

但Prewarm的操作通常都有一定的耗时，建议在可以不用的情况下，将其关闭。

### 引用纹理数超过阈值的粒子系统



### 引用纹理尺寸大于阈值的粒子系统



### 引用网格面片数超过阈值的粒子系统



### 所使用的网格未开启Read/Write选项的粒子系统



### **这里再补充一些常见的优化思路**

对于低端设备尽可能降低粒子系统的复杂程度和屏幕覆盖面积，从而降低其渲染方面的开销，提升低端设备的运行流畅性。具体做法如下：

（1）在中低端机型上降低粒子数、同屏粒子数，比如仅显示“关键”粒子特效或自身角色释放的粒子特效等，从而降低Update的CPU开销；

（2）尝试关闭离当前视域体或当前相机较远的粒子系统，离近后再进行开启，从而避免不必要的粒子系统Update的开销；

（3）尽可能降低粒子特效在屏幕中的覆盖面积，覆盖面积越大，层叠数越多，其渲染开销越大。



引用：[粒子系统优化——如何优化你的技能特效 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/371159292)

[粒子系统优化：Mesh模式下的优化策略 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/311332239)

## 材质

### 包含相同纹理采样的材质

使用相同的纹理进行多次采样

### 包含纯色纹理采样的材质

上图中的纯色纹理其实可以使用一个Color来替代，从而避免实体纹理造成的内存占用，减轻GPU对纹理进行采样的开销，以更高效的处理方式达到同等效果。

### 包含无用纹理采样的材质

在开发过程中，研发团队会依据实际需要的表现效果而对材质球进行Shader的选择与更换。由于Unity自身的机制设定，当切换材质球使用的Shader时，材质球会自动保存上一个Shader的纹理采样信息。

一旦忽略了这方面的处理，就可能会在最终出包的时候，把那些实际不需要的纹理也带进包中，从而造成内存上的浪费。

通过本条检测规则，开发团队就可以把那些包含无用纹理采样的材质全部找出，然后在材质中删除相关的纹理采样信息，减小包体大小，节省空间。

## 网格

### 包含Normal属性的网格

本条规则针对的是网格的Normal属性。在实际运用中，如果网格涉及到了光照、阴影等的应用与计算，那么就需要在网格中导入Normal属性，以达到更好的例如高光、漫反射等表现效果。

和前文讲述的网格Tangent属性类似，Normal属性导入后会对空间和加载性能造成影响。所以在不需要的情况下，我们最好去除网格资源冗余的Normal属性。

### 包含Tangent属性的网格

与Normal相似，一般用于光照计算中的切线空间计算

### 开启Read/Write选项的网格

开启Read/Write后，一个网格数据就会有接近2倍的内存消耗。不需要进行动态编辑和修改的网格一旦开启了Read/Write选项，就会产生不必要的内存开销。

本条规则会筛选出所有开启了Read/Write选项的网格，以供开发团队进行相应的选项关闭和优化。需要提醒的是，对于需要调用函数StaticBatchingUtility.Combine进行合批的Mesh，以及部分Unity版本中粒子系统里使用到的Mesh，它们的Read/Write选项依然需要保持开启。

UWA曾对网格资源进行过相关的深度解析和对比测试，大家可以参考一下相关的文章：[《Unity加载模块深度解析（网格篇）》](https://link.zhihu.com/?target=https%3A//blog.uwa4d.com/archives/LoadingPerformance_Mesh.html)

### 蒙皮网格骨骼数过大

如果模型的骨骼数量较大，那么在运行时会有较高的性能开销，从而对整体的项目性能造成影响。对于该规则目前UWA给的推荐阈值为50，我们建议研发团队对模型的骨骼数进行限制，将该类美术资源的性能开销控制在一个合理的范围内。

### 面片数过大的网格

面片数>500

## 预制

### 使用Tiled模式的Image组件

所以在找出这些使用了Tiled模式的Image组件后，开发团队需要对导入的Texture的WrapMode（Texture为Repeat模式）和Image组件的Type类型进行进一步的检查，以避免上述情况的发生。



引用：[Unity性能优化 — 动画模块 - UWA问答 | 博客 | 游戏及VR应用性能优化记录分享 | 侑虎科技 (uwa4d.com)](https://blog.uwa4d.com/archives/UWA_ReportModule6.html)

[Unity动画优化:Optimize Game Objects_editing and playback of animations on optimized ga-CSDN博客](https://blog.csdn.net/chqj_163/article/details/106135770)

[【性能黑榜】那些年给性能埋过的坑，你跳了吗？（终结篇） - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/260686074)

[材质优化：如何正确处理纹理和材质的关系 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/299127801)

[网格优化：溃堤之穴，一个也不能放过 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/267385857)

[网格优化中，你遇到过哪些吃性能的设置？ - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/266822563)

[Prefab优化：向预制体打出最有效的组合拳 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/337305504)

[UWA本地资源检测说明 - UWA问答 | 博客 | 游戏及VR应用性能优化记录分享 | 侑虎科技 (uwa4d.com)](https://blog.uwa4d.com/archives/pipelinesummary.html)

## 代码

1、空的Update等反射方法，应该删除

2、不要再update等循环中使用new

3、关闭log
