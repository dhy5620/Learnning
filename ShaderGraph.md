# 1、Artistic

## Adjustment

### Invert Colors

Inverts the colors of input **In** on a per channel basis. This [Node](https://docs.unity3d.com/Packages/com.unity.shadergraph@7.2/manual/Node.html) assumes all input values are in the range 0 - 1.

在每个通道的基础上反转输入的颜色。此节点假定所有输入值都在0-1范围内。

### Replace Color

将输入中的值替换为“从输入到输入到”的值。输入范围可用于定义从到替换的输入周围的更宽范围的值。输入模糊性可以用于软化选择周围的边缘，类似于抗锯齿。

# 2、Channel

### Combine

从四个输入R、G、B和A创建新向量。输出RGBA是由输入R、G、B和a组成的向量4。输出RGB是由输入R、G和B组成的向量3。输出RG是由输入R和G组成的向量2。

# 3、Input

## Basic

### Time

Provides access to various **Time** parameters in the shader.

提供对着色器中各种时间参数的访问。与动画相关

# 5、Math

## Advance

### Modulo

Returns the remainder of dividing input **A** by input **B**.

返回输入A除以输入B的余数。

### Negate

返回中输入的翻转符号值。正值变为负值，负值变为正值。

### Reciprocal

Returns the result of dividing 1 by the input **In**. This can be calculated by a fast approximation on Shader Model 5 by setting **Method** to **Fast**.

返回中的输入除以1的结果。这可以通过将“方法”（Method）设置为“快速”（fast）在着色器模型5上进行快速近似来计算。

## basic

### subtract 

相减

Returns the result of input **A** minus input **B**.

### multiply 

叠加

Returns the result of input **A** multiplied by input **B**. If both inputs are a vector type, the output type will be a vector type with the same dimension as the evaluated type of those inputs. If both inputs are a matrix type, the output type will be a matrix type with the same dimension as the evaluated type of those inputs. If one input is a vector type and the other is a matrix type, then output type will be a vector with the same dimension as the vector type input.

返回输入**A**乘以输入**B**的结果。如果两个输入都是向量类型，则输出类型将是向量类型，其维数与这些输入的求值类型相同。如果两个输入都是矩阵类型，则输出类型将是矩阵类型，其维度与这些输入的评估类型相同。如果一个输入是向量类型，另一个是矩阵类型，那么输出类型将是与向量类型输入具有相同维数的向量。

![image-20210512175319982](C:\Users\dinghanyang\AppData\Roaming\Typora\typora-user-images\image-20210512175319982.png)

### add

相加

Returns the sum of the two input values **A** and **B**.

## Interpolation

### Lerp

返回输入T在输入A和输入B之间进行线性插值的结果。输入T的值被限制在0到1的范围内。

例如，当输入T的值为0时，返回值等于输入A的值，当为1时，返回值等于输入B的值，当为0.5时，返回值是两个输入A和B的中点。

### Smoothstep

如果input In的值分别位于input Edge1和Edge2的值之间，则返回0和1之间的平滑Hermite插值的结果。如果input In的值小于input Step1的值，则返回0；如果大于input Step2的值，则返回1。

这个节点类似于Lerp节点，但有两个显著的区别。首先，用户通过该节点指定范围，返回值介于0和1之间。这可以被看作是Lerp节点的对立面。其次，该节点采用平滑Hermite插值代替线性插值。这意味着插值将从开始逐渐加快，到结束逐渐减慢。这对于创建外观自然的动画、淡入淡出和其他过渡非常有用。

## Range

### Fraction 

Returns the fractional (or decimal) part of input **In**; which is greater than or equal to 0 and less than 1.

返回输入的小数部分；大于或等于0且小于1。

### Remap

Returns a value between the x and y components of input **Out Min Max** based on the linear interpolation of the value of input **In** between the x and y components of input **In Min Max**.

基于input In的值在input In Min Max的x和y分量之间的线性插值，返回input Out Min Max的x和y分量之间的值。

### Random Range

基于输入种子返回一个伪随机数值，该值介于由输入Min和Max分别定义的最小值和最大值之间。

虽然输入种子中的相同值将始终导致相同的输出值，但输出值本身将呈现随机性。输入种子是一个向量2值，以便基于UV输入生成随机数，但是对于大多数情况，浮点输入就足够了。

## Round

### step

对于每个组件，如果input In的值大于或等于input Edge的值，则返回1，否则返回0。



## Trigonometry 三角函数

### sine

Returns the sine of the value of input **In**.

## Vector

### distance

返回输入A和B的值之间的欧氏距离。这对于计算空间中两点之间的距离非常有用，通常用于计算有符号距离函数。

### Fresnel Effect

菲涅尔效应是根据观察角度在表面上不同反射的效果，当你接近掠入射角时，更多的光被反射。菲涅耳效果节点通过计算曲面法线和视图方向之间的角度来近似此效果。这个角度越大，返回值就越大。这种效果通常用于实现边缘照明，在许多艺术风格中很常见。

### Dot Product

返回两个输入向量A和B的点积或标量积。

点积等于两个向量的大小相乘，然后再乘以它们之间夹角的余弦。

对于规范化的输入向量，如果它们指向完全相同的方向，则点积节点返回1；如果它们指向完全相反的方向，则返回1；如果向量垂直，则返回0。

# 6、Procedural

## Noise

### Gradient Noise

基于输入UV生成渐变或Perlin噪声。产生噪声的尺度由输入尺度控制。

### Simple Noise

基于输入UV生成简单的噪波或值噪波。产生噪声的尺度由输入尺度控制。

### Voronoi

基于输入UV生成Voronoi或Worley噪波。Voronoi噪声是通过计算像素和点阵之间的距离产生的。通过输入角度偏移量控制的伪随机数偏移这些点，可以生成一个单元簇。这些细胞的规模，以及由此产生的噪音，是由输入细胞密度控制。输出单元格包含原始单元格数据。

## shape

### Ellipse 

椭圆	

### rectangle 

矩形	

### rounded rectangle 

圆角矩形	

### polygon 

多边形

## Checkerboard

基于输入UV在输入颜色a和颜色B之间生成交替颜色的棋盘。棋盘刻度由输入频率定义。

# 8、UV

### Polar Coordinates	

将输入UV的值转换为极坐标。在数学中，极坐标系是一个二维坐标系，其中平面上的每个点由与参考点的距离和与参考方向的角度决定。

结果是，输入到UV的x通道被转换为距离由输入中心值指定的点的距离值，相同输入的y通道被转换为围绕该点的旋转角度值。

这些值可以分别用输入值径向标度和长度标度进行缩放。

### Tiling And Offset

Tiles and offsets the value of input **UV** by the inputs **Tiling** and **Offset** respectively. This is commonly used for detail maps and scrolling textures over [Time](https://docs.unity3d.com/Packages/com.unity.shadergraph@7.2/manual/Time-Node.html).

用于UV动画

### Rotate

围绕由“输入中心”（input Center）定义的参照点旋转“输入UV”（input UV）的值。旋转角度单位可通过参数单位选择。

### Twirl

将类似黑洞的旋转扭曲效果应用于输入UV的值。翘曲效果的中心参照点由输入中心定义，效果的总强度由输入强度值定义。输入偏移可用于偏移结果的各个通道。

扭曲UV

### Spherize

将类似于鱼眼摄影机镜头的球形扭曲效果应用于“输入UV”的值。翘曲效果的中心参考点由输入中心定义，效果的整体强度由输入强度值定义。输入偏移可用于偏移结果的各个通道。

球状UV









vertex color 顶点色输入

