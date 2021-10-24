AMesh Filter:一个Mesh，网格信息

Mesh Renderer：Mesh的皮肤，模型的外观

​	通过Material控制模型的渲染

# shader

## 1、概述

​	着色器、在gpu上运行，实现uv动画、水、雾特效

​	渲染流水线：模型投影、定点着色

​	模型顶点运算的时候可以加入顶点shader来干预顶点的位置，顶点着色的时候可以加入像素shder来干预像素的上色

分类：	

​	固定管线着色器（淘汰）：Fixed Function Shader

​	顶点/片元着色器:Vertex/Fragment Shader

​	表面着色器:Surface Shader（对多光源处理比较好，封装的顶点片元着色器）

## 2、GPU编程语言

​	direct3D和openGl

​	3种语言：

​	HLSL direct3D

​	CG	都支持	与c相似

​	glsl	opengl

​	unity使用的是shaderlab，与cg相似

## 3、创建unity shader

Unlit Shader（无光照着色器）：它是一个不包含光照（但包含雾效）的基本顶点/片元着色器

surface Shader:表面着色器

## 4、shadrelab 基础

### 基本结构

shader "name"{

[Properties]//属性

[Subshaders]:{}	"//子着色器"

[Fallback]//显卡不支持时降级

}

### Properties

​	name("displayName",type) = value

​	name:属性的名字，以下划线开始	_name

​	displayName:显示在属性检查器中的名字

​	value:默认值

​	type:值的类型

​		Float、Int、Color(num,num,num,num)、Vector（思维向量）、Range(start,end)、

​		纹理类型：2D（2D纹理）、Rect(矩形纹理属性)、Cube（立方体纹理属性）、3D(3D纹理)

使用纹理的时候：name("displayName",2D) = "name"{options}

options:纹理属性选项

​	TexGen:纹理生成模式，纹理自动生成纹理坐标的模式；顶点shader会忽略这个选项

​			OjectLinear、Eyelinear、SphereMpa、CubeReflect、CubeNormal

​	LightmapMod:光照贴图模式，纹理会被光照贴图影响

定义：

​	_Range("range value",Range(0,1)) = 0.3

​	_Color("color",Color) = (1,1,1,1)

​	_FloatValue("float",Float) = 1

​	_MainTex("main texture",2D)="skybox"{TexGen CubeReflect}



//float 32位 
//half	16位 -6万 6万
//fixed 11位 -2 2一般颜色用这个

### SubShader

​	SubShader{[Tags],[CommonState],Pass{}}	

​	优先渲染被每个通道定义的对象

​	通用类型：RegularPass、UsePass、GrabPass

### UNITYCG常用函数

#### 摄像机方向

WorldSpaceViewDir(float4 v)	模型上的顶点坐标 -> 世界空间中这个点到摄像机的方向

UnityWorldSpaceViewDir(float4 v)	世界空间的顶点坐标 -> 世界空间中这个点到摄像机的方向

ObjSpaceViewDir(float4 v)	模型上的顶点坐标 -> 模型空间中这个点到摄像机的方向

#### 光源方向

WorldSpaceLightDir(flaot4 v)	模型上的顶点坐标 -> 世界空间中这个点到光源的方向

UnityWorldSpaceLightDir(float4 v)	世界空间的顶点坐标 -> 世界空间中这个点到光源的方向

ObjSpaceLightDir(float4 v)	模型上的顶点坐标 -> 模型空间中这个点到光源的方向

#### 方向转换

​	UnityObjectToWorldNormal  模型 -> 世界 发现

​	UnityObjectToWorld	模型 -> 世界

​	UnityWorldToObject	世界 -> 模型

![image-20210103232221706](C:\Users\dhy54\AppData\Roaming\Typora\typora-user-images\image-20210103232221706.png)

### 	语义

	从应用程序传递到顶点函数的语义	a2v
	float4 vertex:POSITION;//顶点坐标 模型空间下的坐标
	float3 nomal:NORMAL;//法线方向 空间下的法线防线给normal
	float3 tangent:TANGENT;	//切线
	float4 texcoord:TEXCOORD0 ~ n;//纹理坐标 0-1 把第一套纹理坐标给texcoord
	float4 color:COLOR;//顶点颜色
	
	从顶点函数传递到片元函数 v2f
	float4 SV_POSITION	//解释返回值，剪裁空间下的顶点坐标 一般由系统使用
	float4 COLOR0 //可以传递一组值 4个
	float4 COLOR1 //可以传递一组值 4个
	float4 TEXCOORD0 ~ 7;//纹理坐标 0-1 把第一套纹理坐标给
	
	片元函数传递给系统
	float4 SV_Target //显示到屏幕上的颜色
### 光照模型

光照模型是一个公式，使用这个公式来计算某个点的光照效果

标准光照模型，我们把进入摄像机的光分为以下四个部分

​	自发光：自己均匀发光

​	高光发射：类似镜子的光滑材质，沿法线对称反射	specular

​			specular = 直射光 *  pow(max(0,cos(θ)),高光的参数)	θ = 反射光方向和视野方向的夹角 高光参数越大，颜色范围越小

​	漫反射：类似木头的粗糙材质，认为它是均匀的向四周反射	diffuse

​			diffuse = 直射光 *  max(0,cos(θ))	θ = 光和法线的夹角	 cos(θ) = 光单位向量 点乘 法线单位向量

​			推导公式：a**·**b**=|**a**||**b**|·cosθ

​	环境光：均匀的光

Tags{"LightMode" = "ForwardBase"}

只有定义了正确的LightMode,才能得到一些Unity的内置光照变量

#include "Lighting.cginc"

包含unity的内置文件才可以使用unity的内置变量

逐顶点光照：根据顶点计算光照

逐片元光照：根据像素计算光照

normalize：向量单位化

max:取最大啊值

dot	点乘

_LightColor0	第一个直射光的颜色 
_WorldSpaceLightPos0	第一个直射光的位置

UnityObjectToClipPos	将坐标从模型空间转换到剪裁空间

//Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

_World2Object	将一个方向从世界空间转换到模型空间。在矩阵中放在后面，就是将方向从模型空间转换到世界空_

_//Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

mul	矩阵相乘

fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rbg;	环境光	

#### 兰伯特光照模型

​	直射光 *  max(0,cos(光和法线的夹角)) 

#### 半兰伯特光照模型

​	直射光 *  （0.5+ 0.5 *cos(光和法线的夹角)) 

#### 高光反射 BLINN光照模型

​	specular = 直射光 *  pow(max(0,cos(θ)),高光的参数)	θ = 反射光方向和视野方向的夹角 高光参数越大，颜色范围越小

				// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
				//反射光方向
				fixed3 reflectDir = normalize(reflect(-lightDir, nomalDir));
				//顶点在世界的位置 mul(v.vertex, (float3x3)unity_WorldToObject);
				//摄像机的位置_WorldSpaceCameraPos.xyz
				//视野方向
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(v.vertex, 	(float3x3)unity_WorldToObject).xyz);
				//高光反射
				fixed3 specular = _LightColor0.rgb * pow(max(0, dot(viewDir, reflectDir)), 10);

#### BLINN-PHONE光照模型

​	specular = 直射光 *  pow(max(0,cos(θ)),高光的参数)	θ = 法线与x的夹角	x是光与视野方向的平分线

### 纹理贴图

​	纹理坐标 UV；

​	纹理的颜色代替漫反射的颜色；

​	在片元中计算，颜色多，不能通过差值获取；

	//顶点函数获取纹理的uv
	f.uv = v.texcoord;
	//对uv做缩放和偏移
	f.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
	//片元函数获取纹理对应点的颜色
	fixed3 texColor = tex2D(_MainTex, f.uv.xy);

offset控制图片的偏移

tilling控制图片的缩放

#### 纹理类型

texture	贴图 纹理的；normal map 发现贴图；Editor编辑器下使用的图片；sprite UI使用；cursor	鼠标；cube map 环境盒子；cookie	给光生成团；Lightmap	光照贴图；

wrap mode:	uv超出图片之后，repeat重复；clap剪切；

filter mode:滤波；

### shader中的空间与坐标

https://blog.csdn.net/lyh916/article/details/50906272

https://blog.csdn.net/ww1351646544/article/details/88655948

https://blog.csdn.net/bonchoix/article/details/8619624

### 凹凸映射 法线贴图

通过改变法线，让模型有凹凸效果。

降低三角面个数，使用凹凸映射，让模型降低面数，但细节较好。

法线贴图中的颜色值代表模型上的法线。

颜色值范围：0 ~ 1；法线向量：-1 ~ 1

pixel = (normal + 1) / 2;normal = pixel * 2 - 1;

法线贴图是切线空间下的；使用模型空间的话限制了法线贴图的复用；

_NormalMap("normal map",2D) = "bump"{}	//使用模型自带的法线贴图

	//unity自带的将法线贴图颜色值转换到切线空间的方法
	fixed4 normalcolor = tex2D(_NormalMap, f.uv.zw);
	//fixed3 tangentNormal = normalize(normalcolor.xyz * 2 - 1);
	fixed3 tangentNormal = normalize(UnpackNormal(normalcolor));
	TANGENT_SPACE_ROTATION;//调用之后，得到一个rotation矩阵，可以吧模型空间转换到切线空间
	//ObjSpaceLightDir(v.vertex)//模型空间下平行光的方向
	f.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));


	//放在透明队列渲染
	SubShader
	Tags{"Queue" = "Transparent" "IngnoreProjector" = "True" "RenderType"="Transparent"}
	
	Pass
	//关闭深度写入
	ZWrite off
	//透明混合
	Blend SrcAlpha OneMinusSrcAlpha