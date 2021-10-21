# **模板测试概要**

stencil与颜色缓冲区和深度缓冲区类似，模板缓冲区可以为屏幕上的每个像素点保存一个无符号整数值(通常的话是个8位整数)。这个值的具体意义视程序的具体应用而定。在渲染的过程中，可以用这个值与一个预先设定的参考值相比较，根据比较的结果来决定是否更新相应的像素点的颜色值。这个比较的过程被称为模板测试。**模板测试发生在透明度测试（alpha test）之后，深度测试（depth test）之前**。如果模板测试通过，则相应的像素点更新，否则不更新。图形渲染管线中，基于单个像素的测试操作的顺序如下图

![img](http://gadimg-10045137.image.myqcloud.com/20180919/5ba1da6461148.png)

# 重点：

- 注意渲染顺序：一定要先渲染模板，将模板值输入模板缓冲，然后再渲染要被遮挡的物体
- 模板失败，Fail
- 模板成功，深度失败：ZFail
- 模板成功，深度成功：Pass

# 模板测试语法

一般来说，stencil完整语法格式如下：

```
stencil｛
	Ref referenceValue
	ReadMask  readMask
	WriteMask writeMask
	Comp comparisonFunction
	Pass stencilOperation
	Fail stencilOperation
	ZFail stencilOperation
｝
```

## **Ref**

```
Ref referenceValue
```

Ref用来设定参考值referenceValue，这个值将用来与模板缓冲中的值进行比较。referenceValue是一个取值范围位0-255的整数。

## **ReadMask**

```
ReadMask  readMask
```

ReadMask 从字面意思的理解就是读遮罩，readMask将和referenceValue以及stencilBufferValue进行按位与（&）操作，readMask取值范围也是0-255的整数，默认值为255，二进制位11111111，即读取的时候不对referenceValue和stencilBufferValue产生效果，读取的还是原始值。

## **WriteMask**

```
WriteMask writeMask
```

WriteMask是当写入模板缓冲时进行掩码操作（按位与【&】），writeMask取值范围是0-255的整数，默认值也是255，即当修改stencilBufferValue值时，写入的仍然是原始值。

## **Comp**

```
Comp comparisonFunction
```

Comp是定义参考值（referenceValue）与缓冲值（stencilBufferValue）比较的操作函数，默认值：always

## **Pass**

```
Pass stencilOperation
```

**Pass是定义当模板测试和深度测试通过时**，则根据（stencilOperation值）对模板缓冲值（stencilBufferValue）进行处理，默认值：keep

## **Fail**

```
Fail stencilOperation
```

Fail是定义当模板测试失败时，则根据（stencilOperation值）对模板缓冲值（stencilBufferValue）进行处理，默认值：keep

## **ZFail**

```
ZFail stencilOperation
```

**ZFail是定义当模板测试通过而深度测试失败时**，则根据（stencilOperation值）对模板缓冲值（stencilBufferValue）进行处理，默认值：keep

Comp，Pass,Fail 和ZFail将会应用给背面消隐的几何体（只渲染前面的几何体），除非Cull Front被指定，在这种情况下就是正面消隐的几何体（只渲染背面的几何体）。你也可以精确的指定双面的模板状态通过定义CompFront，PassFront，FailFront，ZFailFront（当模型为front-facing geometry使用）和ComBack，PassBack，FailBack，ZFailBack（当模型为back-facing geometry使用）

# **模板测试判断依据**

和深度测试一样，在unity中，每个像素的模板测试也有它自己一套独立的依据，具体公式如下：

```
if（referenceValue&readMask comparisonFunction stencilBufferValue&readMask）
通过像素
else
抛弃像素
```

在这个公式中，主要分comparisonFunction的左边部分和右边部分

referenceValue是有Ref来定义的，这个是由程序员来定义的，readMask是模板值读取掩码，它和referenceValue进行按位与（&）操作作为公式左边的结果，默认值为255，即按位与（&）的结果就是referenceValue本身。

stencilBufferValue是对应位置当前模板缓冲区的值，同样与readMask做按位掩码与操作，结果做为右边的部分

comparisonFunction比较操作通过Comp命令定义，公式左右两边的结果将通过它进行判断，其取值及其意义如下面列表所示。

# **比较操作**

| Greater  | 相当于“>”操作，即仅当左边>右边，模板测试通过，渲染像素    |
| -------- | --------------------------------------------------------- |
| GEqual   | 相当于“>=”操作，即仅当左边>=右边，模板测试通过，渲染像素  |
| Less     | 相当于“<”操作，即仅当左边<右边，模板测试通过，渲染像素    |
| LEqual   | 相当于“<=”操作，即仅当左边<=右边，模板测试通过，渲染像素  |
| Equal    | 相当于“=”操作，即仅当左边=右边，模板测试通过，渲染像素    |
| NotEqual | 相当于“!=”操作，即仅当左边！=右边，模板测试通过，渲染像素 |
| Always   | 不管公式两边为何值，模板测试总是通过，渲染像素            |
| Never    | 不敢公式两边为何值，模板测试总是失败 ，像素被抛弃         |

# **模板缓冲值的更新**

在上一步的模板测试之后，无论模板测试通过与否，都要对模板进行相应的更新。具体到怎么更新，则由程序员自己定义。上面关于模板缓冲语法中，Pass，Fail，ZFail等命令就是根据不同判断条件对模板缓冲区的值（stencilBufferValue）进行更新的操作，这些命令取值（stencilOperation）的类型及意义如下面列表所示：

| Keep     | 保留当前缓冲中的内容，即stencilBufferValue不变。             |
| -------- | ------------------------------------------------------------ |
| Zero     | 将0写入缓冲，即stencilBufferValue值变为0。                   |
| Replace  | 将参考值写入缓冲，即将referenceValue赋值给stencilBufferValue。 |
| IncrSat  | stencilBufferValue加1，如果stencilBufferValue超过255了，那么保留为255，即不大于255。 |
| DecrSat  | stencilBufferValue减1，如果stencilBufferValue超过为0，那么保留为0，即不小于0。 |
| Invert   | 将当前模板缓冲值（stencilBufferValue）按位取反               |
| IncrWrap | 当前缓冲的值加1，如果缓冲值超过255了，那么变成0，（然后继续自增）。 |
| DecrWrap | 当前缓冲的值减1，如果缓冲值已经为0，那么变成255，（然后继续自减）。 |



在更新模板缓冲值的时候，也有writeMask进行掩码操作，用来对特定的位进行写入和屏蔽，默认值为255（11111111），即所有位数全部写入，不进行屏蔽操作。

举个如下的例子：

```
stencil｛
	Ref 2
	Comp always
	Pass replace
｝
```

在上面的代码中，第一行Ref 2这行将referenceValue定义为2；

第二行中，Comp命令后的参数是always，此时我们不管stencilBufferValue为多少，模板测试都是成功通过的；

而第三行中，Pass replace的意思是，当模板测试通过则将referenceValue替换给stencilBufferValue，此时stencilBufferValue值为2，因此上面的例子功能相当于将stencilBufferValue刷新为2；

**小结**

**上面说了这么多，主要的重点如下**

- **使用模板缓冲区最重要的两个值：当前模板缓冲值（stencilBufferValue）和模板参考值（referenceValue）**
- **模板测试主要就是对这个两个值使用特定的比较操作：Never，Always，Less ，LEqual，Greater，Equal等等。**
- **模板测试之后要对模板缓冲区的值（stencilBufferValue）进行更新操作，更新操作包括：Keep，Zero，Replace，IncrSat，DecrSat，Invert等等。**
- **模板测试之后可以根据结果对模板缓冲区做不同的更新操作，比如模板测试成功操作Pass，模板测试失败操作Fail，深度测试失败操作ZFail，还有正对正面和背面精确更新操作PassBack，PassFront，FailBack等等。**

**实例操作**

上面主要是理论知识，下面将通过一个实例大概了解下stencil的简单应用，使用stencil缓冲用来限制渲染区域，效果如下：

![Unity3D Stencil Test模板测试详解](http://gadimg-10045137.image.myqcloud.com/20180308/5aa0eae82efc8.gif)

这个实例需要两个shader实现，如上面的那个用来限制区域的box所使用的shader中的关键代码：

```
ColorMask 0
ZWrite Off
Stencil｛
	Ref 1
	Comp Always
	Pass Replace
｝
```

上面这段代码中，ColorMask 0作用是屏蔽颜色的输出，即不输出颜色到屏幕。ZWrite Off用来关闭深度写入，防止深度测试中后面的角色的像素被剔除掉；在stencil中 Ref 1将referenceValue设置成1，Comp Always 保证模板测试始终通过，Pass Replace 操作则将stencilBufferValue刷新为1；即这段代码的功能是在屏幕上对应模型的位置不输入任何颜色，而将对应位置的模板缓冲值刷新为1；

接下来需要在角色使用的shader中添加如下关键代码：

```
Stencil ｛
      Ref 1
      Comp Equal
｝
```

上面这段代码中，Ref 1将referenceValue设置成1，在接下来的一行代码中，Comp Equal的意思是，如果referenceValue=stencilBufferValue，则模板测试通过，渲染像素，否则抛弃；在这个例子中，由于屏幕中的像素默认的模板值（stencilBufferValue）为0（我猜的，貌似是正确的哈）而参考值referenceValue为1，所以正常情况下使用这个shader的模型是不显示的，但是在使用了第一个shader的box区域，由于stencilBufferValue被刷新为1，所以在这个区域中，角色是能够显示的。

本例完整代码如下：

```
Shader "Custom/UnlitStencilMaskVF" ｛
	SubShader ｛
        Tags ｛ "RenderType"="Opaque" "Queue"="Geometry-1"｝
        CGINCLUDE
            struct appdata ｛
                float4 vertex : POSITION;
            ｝;
            struct v2f ｛
                float4 pos : SV_POSITION;
            ｝;
            v2f vert(appdata v) ｛
                v2f o;
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                return o;
            ｝
            half4 frag(v2f i) : SV_Target ｛
                return half4(1,1,0,1);
            ｝
        ENDCG
        Pass ｛
        ColorMask 0
	    ZWrite Off
	    Stencil
        ｛
            Ref 1
            Comp Always
            Pass Replace
        ｝
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
        ｝   
    ｝ 
｝
Shader "Custom/UnlitStencilVF" ｛
	Properties ｛
	_MainTex ("Base (RGB)", 2D) = "white" ｛｝
｝
SubShader ｛
	Tags ｛ "Queue" = "Geometry""RenderType"="Opaque" ｝
	LOD 100
	Pass ｛ 
		Stencil
        ｛
            Ref 1
      	    Comp Equal
        ｝ 
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#include "UnityCG.cginc"
			struct appdata_t ｛
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			｝;
			struct v2f ｛
				float4 vertex : SV_POSITION;
				half2 texcoord : TEXCOORD0;
				UNITY_FOG_COORDS(1)
			｝;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			v2f vert (appdata_t v)
			｛
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
								UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			｝
			fixed4 frag (v2f i) : SV_Target
			｛
				fixed4 col = tex2D(_MainTex, i.texcoord);
				UNITY_APPLY_FOG(i.fogCoord, col);
				UNITY_OPAQUE_ALPHA(col.a);
				return col;
			｝
		ENDCG
	｝
｝
```