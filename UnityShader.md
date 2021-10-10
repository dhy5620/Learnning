# 1、Properties



# 2、SubShader

## Tag

### RenderType

RenderType通常使用的值包括：

Opaque: 用于大多数着色器（法线着色器、自发光着色器、反射着色器以及地形的着色器）。
Transparent:用于半透明着色器（透明着色器、粒子着色器、字体着色器、地形额外通道的着色器）。
TransparentCutout: 蒙皮透明着色器（Transparent Cutout，两个通道的植被着色器）。
Background: Skybox shaders. 天空盒着色器。
Overlay: GUITexture, Halo, Flare shaders. 光晕着色器、闪光着色器。
TreeOpaque: terrain engine tree bark. 地形引擎中的树皮。
TreeTransparentCutout: terrain engine tree leaves. 地形引擎中的树叶。
TreeBillboard: terrain engine billboarded trees. 地形引擎中的广告牌树。
Grass: terrain engine grass. 地形引擎中的草。
GrassBillboard: terrain engine billboarded grass. 地形引擎何中的广告牌草。

这些RenderType的类型名称实际上是一种约定，用来区别这个Shader要渲染的对象，当然你也可以改成自定义的名称，只不过需要自己区别场景中不同渲染对象使用的Shader的RenderType的类型名称不同，**也就是说RenderType类型名称使用自定义的名称并不会对该Shader的使用和着色效果产生影响**。

### Queue

渲染队列，用来指定当前shader作用的对象的渲染顺序： 
Unity中的几种内置的渲染队列，**深度相同时根据Queue决定渲染顺序**，队列数越小的，越先渲染，队列数越大的，越后渲染。

Background（1000） 最早被渲染的物体的队列。
Geometry （2000） 不透明物体的渲染队列。大多数物体都应该使用该队列进行渲染，也是Unity Shader中默认的渲染队列。
AlphaTest （2450） 有透明通道，需要进行Alpha Test的物体的队列，比在Geomerty中更有效。
Transparent（3000） 半透物体的渲染队列。一般是不写深度的物体，Alpha Blend等的在该队列渲染。
Overlay （4000） 最后被渲染的物体的队列，一般是覆盖效果，比如镜头光晕，屏幕贴片之类的

RenderPipeline

IgnorProjector

## Pass

Blend

ZWrite

ZTest

ColorMask

Lighting

Fog

### HLSL

HLSLPROGRAM

ENDHLSL

### CBUFF

CBUFFER_START

CBUFFER_END

### Include

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"     

### Vert Frag

  #pragma vertex vert
  #pragma fragment frag

            struct Attributes
            {
                float4 positionOS   : POSITION;                 
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };
     
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }
     
            half4 frag() : SV_Target
            {
                // Returning the _BaseColor value.                
                return _BaseColor;
            }


