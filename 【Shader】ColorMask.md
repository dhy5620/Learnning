# ColorMask

ColorMask RGB | A | 0 | 其他R,G,B,A的组合

ColorMask R，意思是输出颜色中只有R通道会被写入

ColorMask 0，意思是不会输出任何颜色

默认值为RGBA，即四个通道都写入

1.ColorMask R

效果如下，可以看出输出颜色并不是红色。因此推出，“只有R通道会被写入”并不是说写入的颜色就是(R,0,0)，那么G,B这两个通道的值是怎么取的呢？经试验取的是摄像机的Background值。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200630003824363.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MzM1MDgwNA==,size_16,color_FFFFFF,t_70)
2.ColorMask 0

如下两图，第一个是ColorMask RBGA，第二个是ColorMask 0。ColorMask 0虽然不写入颜色，但是默认是开启深度写入的，因此重叠部分的像素还是会被舍弃掉的
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200630003841162.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MzM1MDgwNA==,size_16,color_FFFFFF,t_70)
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200630003852893.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MzM1MDgwNA==,size_16,color_FFFFFF,t_70)