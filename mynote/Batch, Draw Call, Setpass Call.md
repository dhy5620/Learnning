如果GPU侧遇到了瓶颈，那么我们首先要入手考虑的点就是纹理填充率和显存带宽。纹理填充率主要是GPU渲染像素的速度，实际工作当中需要从shader复杂度，overdraw开销，屏幕分辨率，后处理等着手改善，显存带宽则主要是GPU和显存进行数据交换的速度，实际工作当中需要从顶点数，顶点复杂度，纹理大小，纹理采样数量，后处理等着手改善。如果CPU侧遇到了瓶颈，那么我们要入手考虑的点主要是程序逻辑执行的复杂度，drawcall等着手考虑。而我们今天要谈论的话题，显然就是从CPU侧入手尝试改善渲染效率。

**Set Pass Call代表渲染状态切换**，主要出现在材质不一致的时候，进行渲染状态切换。我们知道一个batch包括，提交vbo，提交ibo，提交shader，设置好硬件渲染状态，设置好光源属性等（注意提交纹理严格意义上并不包括在一个batch内，纹理可以被缓存并多帧复用）。如果一个batch和另一个batch使用的不是同种材质或者同一个材质的不同pass，那么就要触发一次set pass call来重新设定渲染状态。例如，Unity要渲染20个物体，这20个物体使用同种材质（但不一定mesh等价），假设两次dynamic batch各自合批了10个物体，则对于这次渲染，set pass call为1（只需要渲染一个材质），batch为2（向GPU提交了两次VBO，IBO等数据）。

Draw call严格意义上，CPU每次调用图形API的渲染函数（使用OpenGL举例，是glDrawElements或者DrawIndexedPrimitive）都算作一次Draw Call，但是对于Unity而言，它可以多个Draw Call合并成一个Batch去渲染。

真正造成开销较大的地方，第一个在于在于切换渲染状态，第二在于整理和提交数据。在真正的实践过程当中，可以不用过于介意Draw call这个数字（因为没有提交数据或者切换渲染状态的话，其实多来几个draw call没什么所谓），但是Set Pass Call和Batch两个数字都要想办法降低。由于二者存在强相关性，那么通常降低一个，就一并可以降低第二个。

**Unity提供了三种批次合并的方法，分别是Static Batching，GPU Instancing和Dynamic Batching**。它们的原理分别如下：

## Static Batching

​	将静态物体集合成一个大号vbo提交，但是只对要渲染的物体提交其IBO。这么做不是没有代价。比如说，四个物体要静态批次合并前三个物体每个顶点只需要位置，第一套uv坐标信息，法线信息，而第四个物体除了以上信息，还多出来切线信息，则这个VBO会在每个顶点都包括所有的四套信息，毫无疑问组合这个VBO是要对CPU和显存有额外开销的。要求每一次Static Batching使用同样的material，但是对mesh不要求相同。

**相同材质的静态物体在场景中勾选好static标签**



## Dynamic Batching

​	将物体动态组装成一个个稍大的vbo+ibo提交。这个过程不要求使用同样的mesh，但是也一样要求同样的材质。但是，由于每一帧CPU都要将每个物体的顶点从模型坐标空间变换到组装后的模型的坐标空间，这样做会带来一定的计算压力。所以对于Unity引擎，**一个批次的动态物体顶点数是有限制的。**

​		动态合批处理动态的GameObjects的每个顶点都有一定的开销，因此动态合批处理仅应用于包含不超过900个顶点和不超过300个顶点的网格。

- 如果shader中使用Vertex Position, Normal和single UV，可以批量处理最多300个顶点，而如果shader中使用Vertex Position, Normal, UV0, UV1和Tangent，则只能使用180个顶点。

- **注意**：将来可能会更改属性计数限制。

  如果GameObjects在Transform上包含镜像，则不会对其进行动态合批处理（例如，scale 为1的GameObject A和scale为-1的GameObject B无法一起动态合批处理）。

## GPU Instancing

​	是只提交一个物体的mesh，但是将多个使用同种mesh和material的物体的差异化信息（包括位置，缩放，旋转，shader上面的参数等。shader参数不包括纹理）组合成一个PIA提交。在GPU侧，通过读取每个物体的PIA数据，对同一个mesh进行各种变换后绘制。这种方式相比static和dynamic节约显存，又相比dynamic节约CPU开销。但是相比这两种批次合并方案，会略微给GPU带来一定的计算压力。但这种压力通常可以忽略不计。限制是必须相同材质相同物体，但是不同物体的材质上的参数可以不同。

所以Unity默认策略是优先static，其次gpu instancing，最后dynamic。当然如果顶点数过于巨大（比如渲染它几千颗使用同种mesh的树），那么gpu instancing或许比static batching是一个更加合适的方案。

​	shader上的选项：enable gpu instancing

​	可以通过编写shader实现相同材质不同颜色等等

机型限制：android和ios上 opengl core 4.1+/Es3.0+