# 1、Gamma、Linear与SRGB

​	**由于人眼识别的颜色与物理世界的颜色（或者称之为颜色的数学表达）存在着差距，因此颜色需要进行Gamma校正。**

​	PS：历史上最早的显示器(阴极射线管)显示图像的时候，电压增加一倍，亮度并不跟着增加一倍。即输出亮度和电压并不是成线性关系的，而是呈亮度增加量等于电压增加量的2.2次幂的非线性关系。**这一点已经不重要，现代依然需要Gamma校正。**原因如下：

- gamma值就是对动态范围内亮度的非线性存储/还原算法。
- gamma值的存在，归根到底，是一个解决方案，用于化解“无限的自然存在，与有限的存储容量/传输带宽”之间的矛盾。
- 人类对于外界刺激变化程度的感受，是指数形式的。

​	**最后，什么是sRGB呢？**1996年，微软和惠普一起开发了一种标准**sRGB**色彩空间。这种标准得到许多业界厂商的支持。**sRGB对应的是Gamma0.45所在的空间**。

引用：[Unity 中的Gamma 和 Linear - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/349794457)

[Gamma、Linear、sRGB 和Unity Color Space，你真懂了吗？ - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/66558476)

[Gamma校正与线性工作流入门讲解_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV15t411Y7cf/?spm_id_from=333.1007.top_right_bar_window_default_collection.content.click)

# 2、Unity中的Gamma与Linear

## Gamma与Linear的区别

​	Unity中颜色空间可以通过projectsetting设置，两种空间的区别：

​			Gamma空间和美术大多数DCC软件的输出图会更一致

​			Linear空间通常需要进行较多设置的转换

​	那么两种空间通常我们这样取舍：如果是做简单的手绘类型或者传统次世代效果，gamma和linear其实都差不多，但如果是做pbr材质，gamma意味着对比度更强亮部暗部很难控，亮部曝暗部脏，而linear的显示会更契合pbr的真实感，光感更[线性](https://so.csdn.net/so/search?q=线性&spm=1001.2101.3001.7020)。**做pbr最佳选择linear**。

引用：[关于unity颜色空间选择gamma还是linear_unity中的linear和gamma哪一个好-CSDN博客](https://blog.csdn.net/uljitfk/article/details/79568873)

## PBR是什么

​	PBR就是Physically-Based Rendering的缩写，意为基于物理的渲染。它提供了一种光照和渲染方法，能够更精确的描绘光和表面之间的作用

​	PBR有两种主要的工作流（指数据以何种形式输入到引擎中）：

​			Metallic/Roughness（金属值/粗糙度）：Metallic由于使用了统一的非金属F0值而减少了因非金属F0值出错的可能性而更易于创作，其占用的贴图内存也更少，是目前被采用最多的工作流程。但Metallic的缺点是无法控制非金属的F0值（在有些工具中，例如UE4，可以通过Specular输入来改变F0值），在低分辨率贴图中边缘瑕疵问题会比较明显。

​			Specular/Glossiness（镜面反射/光泽度）：Specular工作流边缘瑕疵是黑色的，相较于前者的边缘瑕疵较为不明显，可以在specular贴图中控制非金属的F0值。但是相对的，Specular能够控制非金属F0值，因而在使用中更有可能导致错误值，能量守恒法则有可能会被打破，也会占用更多贴图内存：2RGB+1灰度图（镜面反射图是RGB贴图），它使用了与传统工作流程相同的术语，但却需要不同的数据，容易令人困惑。

​	最后我们总结一下PBR的**关键要素**：

​	1.能量守恒，反射的光线永远不会比照到表面的入射光线更亮。

​	2.菲涅尔。非金属的F0值变动很小，只在2%-5%区间内；而金属的F0值范围在70%-100%。

​	3.Specular强度通过BRDF、roughness或者glossiness贴图和F0反射值来控制。

​	4.光照计算是在线性空间计算的。

**一个好的PBR作品，会把物质的颜色、粗糙度、高光属性等进行分别处理，使得物质体现出更真实的感觉**

引用：[10分钟了解PBR流程-PBR基本原理和概念 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/161950497#:~:text=首先我们来看看什么是PBR，PBR就是Physically-Based Rendering的缩写，意为基于物理的渲染。 它提供了一种光照和渲染方法，能够更精确的描绘光和表面之间的作用。,它不仅 擅长用来表现非常写实的材质，同时也能用来处理风格化的资源 。)

# 3、Unity 中的 gamma、linear 工作流

## 纹理的SRGB如何使用

### gamma 空间上：

​		勾不勾 都无所谓，都当作 没有勾选 纹理格式一样是使用：GL_COMPRESSED_RGB8_ETC2，虽然 unity 引擎不会申请 sRGB 格式，硬件也不会有 sRGB To Linear 处理，但是贴图图像的颜色值是否经过 sRGB 编码的决定于DCC软件产出的贴图是否sRGB颜色空间

### linear 空间上：

​		勾上，那么unity 引擎会申请 sRGB 纹理格式，硬件会 在 sample 后，做 sRGB to Linear （硬件将此纹理提亮；纹理格式为：GL_COMPRESSED_SRGB8_ETC2 （压缩格式取决于 unity 引擎中对此纹理的格式设置，这一小段的内容，我们整理出了下面的表格，并以 ETC2 格式纹理为例））
​		不勾，就是说，硬件把你的纹理直接当做 linear 数据，硬件不会 在 sample 后，不做 sRGB to Linear （不压暗亮度） ，直接给到 shader 着色计算，纹理格式为：GL_COMPRESSED_RGB8_ETC2

### 总结：

​	linear space 下
​		纹理的 sRGB 勾上，说明此说明是 sRGB颜色空间的贴图，此贴图为的是看着更舒服的线性颜色，实际是提亮过的，请 unity 帮我在显示这个贴图的时候 处理压暗 pow(color, 2.2)，并且申请sRGB贴图格式，进行 sRGB 编码提亮，在为的是shader调用sample时，硬件返回颜色前经过 压暗 pow(color, 2.2) 处理的，再返回线性值，用于后续shading的正确性；因此我们看到 inspector 中，一般勾上 sRGB 的话，inspector 中显示贴图会就变暗 （sRGB编码的硬件自动处理过程）
​		纹理的 sRGB 没勾，说明此贴图没有经过 sRGB 编码过， shader调用sample后不会有任何处理就返回
所以你现在应该知道 unity sRGB 的作用了

因此设置unity颜色空间的话，其实除了会影响纹理的 sRGB 的格式外，还会影响 FrameBuffer（下面简称 FB）的格式 （简单总结区别就是： Linear Color Space 下，够了 sRGB 的贴图格式就是 sRGB 的，FBO 的 color attachment 的 纹理格式也是 sRGB 的）

# 4、美术贴图如何使用

​		每个纹理资源只要是颜色类型的纹理（不是 AO, Normal, Height 贴图），那么 sRGB 的勾选需要在对应的 Color Space 下选择是否勾选（简单理解就是，用于给用户颜色直接输出的颜色值的贴图，要是用户给眼睛看的贴图，都是要 sRGB 的）：

## Color Space 为 Gamma 时

​		勾上（Unity 默认情况下时会勾上的）不勾上选都无所谓，因为在 Color Space 为 Gamma 时，纹理是否 sRGB 空间的颜色值，取决于 DCC软件导出是否 sRGB 的

## 在 Color Space 为 Linear 时

​		如果我们美术输出的纹理颜色资源都是在被 压暗过的数据，或者说是在 Gamma 空间下生产的资源，那么 unity 就要勾上 sRGB，让 unity 引擎给这个纹理格式申请一个 sRGB 格式，纹理采样返回前硬件就会先（也就是 pow(val, 2.2)），然后再返回值。
​		如果我们美术输出的纹理颜色资源都是 线性的数据（没有提亮，也就是 dcc软件没有导出 sRGB），那么 unity 中，此贴图就不要勾选 sRGB，就是 shader 中采样这个纹理的时候，因为贴图没有申请为 sRGB 格式，硬件就不会处理 sRGB to linear的过程
​		(但是由于现在很多 DCC 软件输出的颜色纹理默认都是 被提亮过的数据，归根到底就是想要颜色的灰阶让人眼看起来舒服的，也就是 sRGB编码过的，所以一般我们在 unity Linear color spacce 下的颜色纹理默认都会勾上 sRGB，来让 unity 引擎申请此贴图为 sRGB 格式，并采样后，来一遍 sRGB To Linear (pow(val, 2.2)) 后，这压回线性空间：具体顺序：unity sRGB 贴图后处理pow(color,2.2)，申请 sRGB格式硬件编码 pow(color, 1.0/2.2)，shader sample后返回前 pow(color, 2.2))



unity 想要保留 gamma 的处理，因为Linear 空间是有硬件兼容性问题的 (早期没人在渲染管线上考虑到 sRGB 格式的纹理和FBO，因此会有旧版本兼容性的问题)

在 Linear 的颜色空间的话，如果在 Android 平台，那么需要在 Android 4.3 或是 OpenGL 2.0 以上（不含 2.0)）

引用：[Gamma Correction/Gamma校正/灰度校正/亮度校正 - 部分 DCC 中的线性工作流配置_degamma-CSDN博客](https://blog.csdn.net/linjf520/article/details/122201009)

# 5、Linear 空间下，美术贴图在PS与Unity表现有差异

问题描述：如果项目切到过线性空间，或者一开始就在线性空间，而美术制作ui的时候没有做设置，那么很快你就能发现这个问题了。美术会发现他们制作的ui效果和在unity里摆出来的不一样，特别是设计到透明度混合等问题

问题的根源：

        比如AB两个图层，A在上层，B在下层，A的alpha不为1
    
        PS中默认的工作空间是Gamma空间，半透明图层使用的混合公式如下：
    
                color = A.rgb*A.alpha + B.rgb*(1-A.alpha)                        （公式1）
    
        如果unity是Gamma空间，那么同样UI层级的混合公式：
                color = A.rgb * A.alpha + B.rgb *(1-A.alpha)                        （公式2）
    
        如果unity是线性空间，如果图勾选了sRGB，则图被认为是存于gamma空间，则首先转到线性空间，然后进行混合：
    
                color = （A.rgb^2.2 * A.alpha + B.rgb^2.2 * (1-A.alpha)) ^ (1/2.2)                 （公式3）
    
                线转到线性空间内进行混合，然后最后将整个颜色进行gamma编码到gamma空间，因为最后显示器显示的时候会进行gamma矫正
    
                如果没有勾选sRGB，则
    
                color = (A.rgb * A.alpha + B.rgb*(1-A.alpha)) ^(1/2.2)                （公式4）

根据以上的公式来看，如果unity是gamma空间，则很好，ps和unity的效果是一致的。如果unity不在gamma空间，则这里必然会出问题。

## 解决方案：

​		PS gamma Correct 保持 2.2 & 灰度混合系数 1.0 勾上，unity导入后勾选srgb

优缺点
		优点：这种方式，UI、特效美术 几乎是不用修改的 工作流的，只要将：alpha blend 1.0 勾上，而且对 PS 颜色吸管的功能可以保持原有功能效果，所以对美术工作流友好最大
		缺点：每个 UI 或是 特效的 Shader 都要添加 gamma correct（一个 pow运算），如果 overdraw 很多时会放大这个点的性能消耗，但是对于现代显卡来说，应该可以忽略不计

![img](https://img-blog.csdnimg.cn/27323c732a6a4a07b8b2b63d9e1c9ba8.png)

## 注意：

​	注意我们新建文档制作时，确保 勾上 ：用灰度系数混合 RGB 颜色的 勾选项

​	只有在 导出单个图层 的时候，去掉：用灰度系数混合 RGB 颜色的 勾选项

​	导出完毕后，继续制作 PSD 内容的时候，需要 再次 勾上：用灰度系数混合 RGB 颜色的 勾选项

总结三句话：

​		平时制作时 确保 勾上 ：用灰度系数混合 RGB 颜色的 勾选项
​		在导出单个图层时，去掉：用灰度系数混合 RGB 颜色的 勾选项
​		导出整体效果图时，勾上：用灰度系数混合 RGB 颜色的 勾选项



PS：当然还有一种解决方案，是让美术同学直接在linear空间下工作，但是根据Gamma校正的原理，这是很反人类的，美术同学工作起来相当不便利，这里不展开了。

引用：[Unity线性空间UI的问题_unityui线性-CSDN博客](https://blog.csdn.net/zhjzhjxzhl/article/details/119917984)

[Unity & PS Linear Workflow - Unity 和 PS 的线性工作流实践 - 简单配置示例_photoshop 线性工作流-CSDN博客](https://blog.csdn.net/linjf520/article/details/126672005)

