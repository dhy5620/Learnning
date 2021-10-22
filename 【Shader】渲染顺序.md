# 总结

## 1、Camera Depth: 越小越优先

## 2、RenderQueue 2500以下

	1. Sorting Layer/Order in Layer
​		a. 按照Sorting Layer/Order in Layer 设置的值，越小越优先
​		b. 无此属性，等同于 Sorting Layer=default ,Order in Layer=0 参与排序
​	2.RenderQueue 越小越优先
​	3.RenderQueue 相等，由近到远排序优先

## 3、RenderQueue 2500以上

​	1. Sorting Layer/Order in Layer
​		1. 按照Sorting Layer/Order in Layer 设置的值，越小越优先
​		2. 无此属性，等同于 Sorting Layer=default ,Order in Layer=0 参与排序
​	2.RenderQueue 越小越优先
​	3.RenderQueue 相等，由远及近排序

说明一下：2500是关键值，它是透明跟不透明的分界点，因此我们考虑层级的时候要注意着点：renderqueue > 2500的物体绝对会在renderqueue <= 2500的物体前面，即渲染时renderqueue大的会挡住renderqueue小的，不论它的sortingLayer和sortingOrder怎么设置都是不起作用的。知道了这点，其他的就很好理解了。当两个的RenderQueue都在同一侧时，在SortingLayer高的绝对会在sortingLayer前面，无视renderqueue跟soringOrder，只有在sortingLayer相同的前提下，soringOrder高的会在sortingOrder低的前面，无视renderqueue。当sortingLayer跟sortingOrder相同时，才看renderqueue的高低，高的在前面。

## 4、深度缓冲

深度缓冲（depth buffer | z-buffer）决定哪些物体渲染在前面，哪些物体渲染在后面。基本思想：根据深度缓冲中的值来决定该片元距离摄像机的距离（开启深度测试的前提下），当渲染这个片元时，把它的深度值和已经存在在深度缓冲中的值进行比较（开启深度写入的前提下），如果它的值距离摄像机更远，说明这个片元不用渲染（有物体挡住了它），否则，这个片元应该覆盖掉颜色缓冲中的像素值，并把它的深度值写入深度缓冲中（开启深度写入的前提下）。

渲染顺序确定后，开启深度缓冲，后渲染的东西如果不能通过深度缓冲，则片元会被抛弃。

## 5、注意事项

### 1.特效层级处理

因此只需要每当我们需要在ui中间夹着特效的时候，就有多种解决思路，

一是将ui分别放置于两个不同的sortingLayer，并将特效放于中间的sortingLayer，并保证他们的renderqueue同时在2500的同一侧。

二是将他们的sortingLayer都设置为同一个，并将特效的sortingOrder保持在两个ui的sortingOrder中间即可。

三是保证ui跟特效的sortingOrder跟SortingLayer相同，并保持特效的renderqueue在两个ui的sortingOrder之间即可。

### 2.UGUI组件

Sprite组件和Canvas组件 默认使用的Shader未写入z缓冲，但是进行z缓冲测试 默认 RenderQueue 均为 Transfront=3000




