# Cull 表面剔除

## Cull Back | Front | Off

ShaderLab	Desc	说明
Off	Disables culling - all faces are drawn. Used for special effects.	不剔除
Back	Don’t render polygons facing away from the viewer (default).	剔除背面（内表面）
Front	Don’t render polygons facing towards the viewer. Used for turning objects inside-out.	剔除正面（外表面）

## 什么是表面剔除？为什么要进行表面剔除？

当一个mesh组件的信息被传递后，我们可以通过代码决定哪些部分渲染(render)出来，而哪些部分不要，这个过程就像把那些不要的部分剔除了，**我们看不到他，虽然他的mesh信息还在，但是我们的GPU不会去处理它，肯定比剔除前GPU的性能消耗要低**。
这个过程就好比我们的mesh组件是一个透明的膜，我们假设这个胶纸我们根本看不到，而片段着色器在着色的时候像毛笔选择性地上色，最后的效果是我们可能看到膜的一部分是可见的，但是不见的地方，膜还是存在的，只是我们没有给他上色，我们既看不看他们，也不需要再他们上面画宝贵的墨水(GPU并行处理能力)