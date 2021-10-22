# shader Blend混合模式

## 什么是混合

​      混合是什么呢？混合就是把两种颜色混在一起。具体一点，就是把某一像素位置原来的颜色和将要画上去的颜色，通过某种方式混在一起，从而实现特殊的效果。

假设我们需要绘制这样一个场景：透过红色的玻璃去看绿色的物体，那么可以先绘制绿色的物体，再绘制红色玻璃。在绘制红色玻璃的时候，利用“混合”功能，把将要绘制上去的红色和原来的绿色进行混合，于是得到一种新的颜色，看上去就好像玻璃是半透明的。

## 在OpenGL中使用Blend

### 2.1 初始化说明

​      要使用OpenGL的混合功能，只需要调用：glEnable(GL_BLEND);即可。

​      要关闭OpenGL的混合功能，只需要调用：glDisable(GL_BLEND);即可。

注意：只有在RGBA模式下，才可以使用混合功能，颜色索引模式下是无法使用混合功能的。

​      混合需要把原来的颜色和将要画上去的颜色找出来，经过某种方式处理后得到一种新的颜色。这里把将要画上去的颜色称为“源颜色”，把原来的颜色称为“目标颜色”。

### 2.2 公式说明

数学公式来表达一下这个运算方式。

假设源颜色的四个分量（指红色，绿色，蓝色，alpha值）是 (Rs, Gs, Bs, As)，

目标颜色的四个分量是(Rd, Gd, Bd, Ad)，

又设源因子为(Sr, Sg, Sb, Sa)，

目标因子为 (Dr, Dg, Db, Da)。

则混合产生的新颜色可以表示为：

 (Rs*Sr+Rd*Dr, Gs*Sg+Gd*Dg, Bs*Sb+Bd*Db, As*Sa+Ad*Da) 

如果颜色的某一分量超过了1.0，则它会被自动截取为1.0，不需要考虑越界的[问题](http://www.manew.com/forum-ask-1.html)。

### 2.3 在OpenGL中的使用

选择源混合因子和目标混合因子的方式:

第一种方式是调用函数glBlendFunc(),并指定两个混合因子, 其中第一个参数为源RGBA的混合因子, 第二个参数为目标RGBA的混合因子.

第二种方法是调用glBlendFuncSeparate()并指定4个混合因子, 这样可以用不同的方式来混合RGB和alpha值

第二种方式就不在说了，说下第一种当时中的混合因子的枚举表：

| GL_DST_ALPHA           | ( Ad , Ad , Ad , Ad )        |
| ---------------------- | ---------------------------- |
| GL_DST_COLOR           | ( Rd , Gd , Bd , Ad )        |
| GL_ONE                 | (1,1,1,1)                    |
| GL_ONE_MINUS_DST_ALPHA | (1,1,1,1) - (Ad,Ad,Ad,Ad)    |
| GL_ONE_MINUS_DST_COLOR | (1,1,1,1) - (Rd,Gd,Bd,Ad)    |
| GL_ONE_MINUS_SRC_ALPHA | (1,1,1,1) - (As,As,As,As)    |
| GL_SRC_ALPHA           | ( As , As , As , As )        |
| GL_SRC_ALPHA_SATURATE  | (f,f,f,1) : f = min(As,1-Ad) |
| GL_ZERO                | ( 0 , 0 , 0 , 0 )            |

## unity中的说明

### 3.1 unity中混合简介

混合常用在透明物体渲染中。如下图所示：在所有着色器执行完毕，所有纹理都被应用，所有像素准备被呈现到屏幕之后，使用Blend命令来操作这些像素进行混合。



![img](https://img-blog.csdn.net/20180929213942524?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM1MDMwNDk5/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

### 3.2 blend的语法

​      BlendOff:关闭blend混合（默认值）

​      BlendSrcFactor DstFactor ：配置并启动混合。产生的颜色被乘以SrcFactor. 已存在于屏幕的颜色乘以DstFactor，并且两者将被叠加在一起。

​      BlendSrcFactor DstFactor, SrcFactorA DstFactorA：同上，但是使用不同的要素来混合alpha通道

​      BlendOpBlendOpValue：不是添加混合颜色在一起，而是对它们做不同的操作。

​      BlendOpOpColor, OpAlpha：同上，但是使用不同的操作来处理alpha通道

​      AlphaToMaskOn：里面新添加的，常用在开启多重渲染（MSAA）的地表植被的渲染。

 

Unity中的混合因子（和OpenGL的差不多）：

| One              | 值为1，使用此设置来让源或是目标颜色完全的通过。 |
| ---------------- | ----------------------------------------------- |
| Zero             | 值为0，使用此设置来删除源或目标值。             |
| SrcColor         | 此阶段的值是乘以源颜色的值。                    |
| SrcAlpha         | 此阶段的值是乘以源alpha的值。                   |
| DstColor         | 此阶段的值是乘以帧缓冲区源颜色的值。            |
| DstAlpha         | 此阶段的值是乘以帧缓冲区源alpha的值。           |
| OneMinusSrcColor | 此阶段的值是乘以(1 - source color)              |
| OneMinusSrcAlpha | 此阶段的值是乘以(1 - source alpha)              |
| OneMinusDstColor | 此阶段的值是乘以(1 - destination color)         |
| OneMinusDstAlpha | 此阶段的值是乘以(1 - destination alpha)         |

 

混合的操作符（Blend operations）

| Add                 | Add source and destination together.                  |
| ------------------- | ----------------------------------------------------- |
| Sub                 | Subtract destination from source.                     |
| RevSub              | Subtract source from destination.                     |
| Min                 | Use the smaller of source and destination.            |
| Max                 | Use the larger of source and destination.             |
| LogicalClear        | Logical operation: Clear (0) DX11.1 only.             |
| LogicalSet          | Logical operation: Set (1) DX11.1 only.               |
| LogicalCopy         | Logical operation: Copy (s) DX11.1 only.              |
| LogicalCopyInverted | Logical operation: Copy inverted (!s) DX11.1 only.    |
| LogicalNoop         | Logical operation: Noop (d) DX11.1 only.              |
| LogicalInvert       | Logical operation: Invert (!d) DX11.1 only.           |
| LogicalAnd          | Logical operation: And (s & d) DX11.1 only.           |
| LogicalNand         | Logical operation: Nand !(s & d) DX11.1 only.         |
| LogicalOr           | Logical operation: Or (s \| d) DX11.1 only.           |
| LogicalNor          | Logical operation: Nor !(s \| d) DX11.1 only.         |
| LogicalXor          | Logical operation: Xor (s ^ d) DX11.1 only.           |
| LogicalEquiv        | Logical operation: Equivalence !(s ^ d) DX11.1 only.  |
| LogicalAndReverse   | Logical operation: Reverse And (s & !d) DX11.1 only.  |
| LogicalAndInverted  | Logical operation: Inverted And (!s & d) DX11.1 only. |
| LogicalOrReverse    | Logical operation: Reverse Or (s \| !d) DX11.1 only.  |
| LogicalOrInverted   | Logical operation: Inverted Or (!s \| d) DX11.1 only  |

 

下列是最经常使用的混合类型

Blend SrcAlpha OneMinusSrcAlpha // Alphablending alpha混合

Blend One One // Additive 相加混合

Blend One OneMinusDstColor // Soft Additive柔和相加混合

Blend DstColor Zero // Multiplicative 相乘混合

BlendDstColor SrcColor // 2x Multiplicative 2倍相乘混合