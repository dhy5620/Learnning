**什么是“Mecanim”？**

Mecanim 是我们集成到 Unity 中的动画软件的名称。在早期的 4.x 系列 Unity 中，它的功能与人形角色动画密切相关，并具有许多特别适合此用途的功能；并且它独立于我们旧的（旧版）集成动画系统。

Mecanim 集成了人形动画重定向、肌肉控制和状态机系统。“Mecanim”这个名字来自法语单词“Mec”，意思是“Guy”。由于 Mecanim 仅与人形角色一起运行，因此仍然需要我们的遗留动画系统来为非人形角色和 Unity 中游戏对象的其他基于关键帧的动画制作动画。

不过，我们此后开发并扩展了 Mecanim，并将其与动画系统的其余部分集成，以便能够在您的项目中用于动画的所有方面；因此，“Mecanim”与动画系统的其余部分之间并没有太清晰的分界线。鉴于此原因，您仍然会在我们的文档和整个社区中看到对“Mecanim”的引用，现在这些引用仅仅指的是我们的主动画系统。

## 1. Mecanim 动画系统

> Unity的Mecanim动画系统，是一套基于**状态机**的动画控制系统，是一个**面向动画应用的动画系统**

## 2. 角色模型动画的创建与应用工作流程

> 3dmax(或者其他建模软件)==》FBX==》Unity

## **3. AnimtionClip 动画片段**

Unity中的动画片段分为两种

1. 通过剪辑FBX中的整段动画生成的动画切片（Clip）
2. 以及由Animation窗口创建出的动画片段（Clip）

## 4. Animator

- **Avatar**：动画节点导引替身，与动画复用（尤其是人形动画复用）有关，通过配置和应用Avatar，可以实现不同FBX模型之间的动画复用

- **Apply Root Motion**：是否将动画中的根节点位移，植入到Unity中的物体位移上：详细见第7点

- **Culling Mode**：剔除模式

- - Always Animate：无论物体是否被摄像机可见，总是计算所有节点的运动，完整的进行动画播放
  - Cull Update Transforms：当物体不被摄像机可见时，仅计算根节点的位移植入，保证物体位置上的正确
  - Cull Completely：当物体不被摄像机可见时，完全终止动画的运行
  - 对于玩家操作的主角人物，或者与主角密切相关的，在绝大多数情况下均可见的角色，我们通常使用Always Animate模式
  - 对于一些配角，例如怪物，小兵，这些部分情况下可见的角色，不妨使用Cull Update Transform模式来进行优化，这样在摄像机无法看见它们的时候，它们的根节点运动仍然正确

## 5. AnimatorController

### 5.1 Transitions

5.1.1 条件控制or：从一个状态到另一个状态可以有多条过渡，它们将组成**并集**的效果

5.1.2 条件控制and：

5.1.3 想要重复触发自身动画需要加两个相同的动画片段==》可优化为一个动画片段自己切换。

### **5.2 Has Exit Time**：

> 勾选时上一个状态对于的动画片段必须被播放到末尾，才允许这个过渡被触发，不勾选可以在任意时刻进行过渡

### **5.3 Interruption Source**：

> 打断来源，允许该过渡被来自CurrentState或NextState的其它过渡打断
> 被CurrentState打断则发生了“跳转”，NextState的指向被改变（例如受击打断了攻击）
> 被NextState打断则发生了“跃进”，动画迅速的完成了两个状态的过渡（例如从站立状态快速过渡到冲刺斩，奔跑状态被越过）
> **合理的运用打断，实现快节奏的状态切换，是制作动作游戏的基础**

### **5.4 Ordered Interruption**：

> **针对CurrentState出发的过渡**，是否只允许比当前过渡优先级高的过渡打断该过渡

- Solo：勾选时，该State只能进行该过渡，其它过渡将无效（反选其他）
- Mute：勾选时，这个过渡将无效（有点Disable的意思）
- **这个功能通常被用于调试**，进行一些单向的过渡，或禁止向某个状态进行过渡，从而**在限制性的范围内，观测状态机的运行**

### **5.5 AnyState**

从AnyState出发的条件，相当于Update，unity每帧都会将条件执行一次，所以要注意控制条件数量和复杂度

注意点：

- go的 active false，会导致状态机重置！！！**踩坑\*2！！！**
- 动画状态机完全停止后不能修改参数，会导致隐藏期间玩家动画状态改变后再显示会恢复成错误的参数。
- 因此玩家隐藏期间动画状态改变需要同步修改备份参数。
- 存在问题：状态机完全停止后无法知道玩家当前的正确表现，所以玩家被隐藏后显示虽然能恢复成正确参数，但表现会和不停止状态机有差别。比如一个一直持枪的玩家，在被隐藏显示后会重播一次掏枪动画。

### 5.6 API

- **Animator进行动画重置的两种方式**

- - animator.Play("动画状态名"，动画所在层，动画归一化时间的选择);
  - animator.Update(更新到当前时间的多少时间后); //称为时间增量

## 6. AnimatorOverrideController

> 动态修改State里的AnimatorClip 不支持，只能用 AnimatorOverrideController 去实现 clip 动态替换
> 方法：运行时生成 AnimatorOverrideController 类，动态换掉动画状态机

```text
Animator animator = GetComponent<Animator>();
AnimatorOverrideController overrideController = new AnimatorOverrideController();
overrideController.runtimeAnimatorController = animator.runtimeAnimatorController;
overrideController["name"] = newAnimationClip;
animator.runtimeAnimatorController = overrideController;
```

但是使用的时候需要注意以下几点：

- 注意1：Override操作的时候，消耗的性能会随着AnimatorController里State数量的增加而增加，即是我们并不去使用它们。这个问题就是Override存在的性能热点**。**
- 

- 注意2： 使用AnimatorControllerOverride覆盖AnimationClips时，Animator的状态被重置：[使用AnimatorControllerOverride的坑_chqj_163的博客-CSDN博客](https://link.zhihu.com/?target=https%3A//blog.csdn.net/chqj_163/article/details/107714859)

- 注意！！！编辑器所见并不一定是所得，要以 .overrideController记录的实际信息为主，

- - 出现过没有Ctrl+S，m_Clips 字段为0，但是编辑器表现正常，看到的引用也都是对的，深坑

## 7. 关于Apply **Root Motion**

- Apply Root Motion 不勾选：原地运动
- Apply Root Motion 勾选：向前运动
- 脚本中实现了OnAnimatorMove，相当于勾选了ApplyRootMotion，可以在脚本中控制位置和旋转

### 7.1 通过移动的方向和左右脚点乘判断是哪只脚踩地

点乘：[曾志伟：【GAMES101现代图形学入门】P2 线性代数复习 笔记](https://zhuanlan.zhihu.com/p/361251019)

## **8.** Avatar的作用与配置

## 9. StateMechineBehavior

- StateMechineBehavior 挂在State上：**OnStateEnter/OnStateUpdate/OnStateExit**
- StateMechineBehavior 挂在Layer上：
- **StateMechineBehaviour与Mono的通信**

```csharp
//Awake OR Start
var smb = animator.GetBehaviour<StateMechine>();
//这里会是从父动画组到子动画组以及其中包含的State，这个遍历顺序下，遇到的第一个StateMechine

var smbS = animator.GetBehaviours<StateMechine>();
//返回一个数组包含Controller中所有的StateMechine
```

## 10. 动画分层

### 10.1 使用Mask进行上下分层

动画分层我的理解有点像PS的画布、Unity的Canvas，一层又一层，通过叠加模式进行叠加，最后表现出混合后的动画

使用动画分层的应用主要是以下情况

1. 人物动画状态**涉及分部并行逻辑**，例如枪战游戏，腿部动作由键盘控制，而上半身动作需要由鼠标控制进行IK瞄准，以及武器切换
2. 存在**状态的融合/叠加效果**，例如在正常走动的基础上，搬运物品时，上半身需要持握物品并进行IK绑定，下半身仍是正常走动
3. 动作游戏中，为减轻动画师工作量，**取用不同动作的部分进行组合**

- Weight：混合权重

- Mask：混合蒙版

- Blending：混合模式，两种可选

- - ---Override：**绝对坐标重写**模式，根据权重，Overrid会令下层节点的位置逐渐替换上层节点位置（节点位置按照Weight的Lerp差值效果）
  - ---Additive：**相对运动叠加**模式，根据权重，将该层节点的相对运动效果叠加到上层节点上。如果上层节点在动画中没有运动，将完全表现下层的动画效果，如果上层有运动将与下层节点的运动组成和运动表现出来，如果下层节点不具有相对运动，那么就不对上层产生影响

**测试**

**动画分层方式1：【**Mask = AvatarMask**】** + 【Blend = Override】 + 【Weight = 1】

新建一个 UpperBody 动画分层，BaseLayer是一个跑步动作，UpperBody 是一个跳舞动作，新建一个AvatarMask，把下半身标红遮挡住，赋值到Mask字段，然后Weight拉满，混合模式选择Override，就能实现完全的动画分层

**动画分层方式2：【**Mask = none**】** + 【Blend = Addicted】 + 【Weight = 1】+ 【ClipMask】

不创建AvatarMask，使用ModelImporter的Animation分页下的ClipMask进行遮罩

### 10.2 动画层的 Sync 属性

有时，能够在不同层中复用同一状态机是很有用的。例如，如果想要模拟“受伤”行为，并生成“受伤”状态下的行走/奔跑/跳跃动画，而不是“健康”状态下的动画，您可以单击其中一个层上的 **Sync** 复选框，然后选择要同步的层。随后状态机的结构便会相同，但状态使用的实际动画剪辑不同。

这意味着同步的层根本没有自己的状态机定义，而是同步层状态机的一个实例。在同步层视图中对状态机的布局或结构所做的任何更改（例如，添加/删除状态或过渡）都是针**对同步层的源**进行的。同步层的唯一独特更改是每个状态内使用的选定动画。（我的理解是Override？）

## 11. BlendTree混合树

> BlendTree的作用是**将多个动画状态混合成为一个动画状态**，并**通过动画参数来影响状态的输出结果**
> 使用BlendTree的**目的是应对状态机的高耦合导致的低扩展缺点**，尤其是在人物运动相关的动作（前后左右的行走奔跑）这类繁多的动作

以跳跃为例子，

这样我们就可以在代码层，通过控制 h_moveDir 和 v_moveDir 这2个变量，对角色动画进行控制向4个方向进行跳跃动作

**镜像功能：**

既然UI可以镜像，动画讲道理也可以镜像，上述的4个动画，如果用上镜像功能，那就只要2个动画就行了，资源量直接减少一半。

【当然，这个镜像的前提是完全一样，像向前跳和向后跳，动作还是有点区别的，所以看情况而定】

### 11.1 BlendType

- 1D：1个参数

- 2D：2个参数，3种配置方法都是相同的，不同的混合模式区别在于**动画位点之间的差值过渡方式不同（没懂）**

- - **2D Simple Directional：**整个二维平面的两个维度都被用于区分运动速度/方向的不同，每个动画都应拥有自己独特的运动方向，或者说从原点指向某个动画位点的单位向量各不相同
  - **2D FreeForm Direction：**与前一种类似，但允许出现两个及以上动画同向异速，不过这种模式也要求在原点（0,0）点处应有一个站立/静止状态的动画，从而根据到原点的距离来区分融合同向异速的动画
  - **2D FreeForm Cartesian：**用于融合单一方向运动以及其它非线速度效果，要求所有动画的运动方向应相同，并通过二维平面的一个维度进行速度区分，而另一个维度应是转向，转头等一些非线速度效果的动画

## 12. GPU Skinning

> 骨骼运动信息存储：对动画进行采样，将骨骼结点的动画矩阵信息以纹理的方式进行存储
> 顶点位置更新：在GPU中采样动画纹理，更新顶点位置后直接进行渲染。

### 12.1 骨骼动画信息存储

RBGAHalf （64位，更精准）

- **优点：**

- - 避免Animators.Update与MehSkinning.Update的CPU占用
  - 通过纹理存储，内存占用小
  - 降低CPU开销

- **缺点：**

- - 对于GPU压力更大
  - 低端机无法适配（需要ES3.0以上）

开源库：[GPU Skinning Open Source Project](https://link.zhihu.com/?target=https%3A//lab.uwa4d.com/lab/5bc6f85504617c5805d4eb0a)

项目实践：[曾志伟：【GPU Instance】从入门到过载](https://zhuanlan.zhihu.com/p/587434503)

## 13. [GPU Instancing](https://zhuanlan.zhihu.com/p/356211912)

## 14. Animation时序

- ProcessAnimations 读取骨骼信息

- FireAnimationEventsAndBehaviours 读取动画事件

- ApplyOnAnimatorMove 根节点应用动画信息

- WriteAnimatedValues 动作数值写入

- DirtySceneObjects 对骨骼的transform进行更新写入

- MeshSkinning.CalcMatrices 计算蒙皮矩阵

- ScheduleGeometryJobs 子线程处理

- MeshSkinning.Skin 计算模型，网格顶点位置

- MeshSkinning.Render 渲染

- - PutGeometryJobFench 几何计算
  - Mesh.DrawVBO DrawCall调用

## 15. Playables API

Playables API 是动画系统底层接口，Animator是基于 Playables API 的封装。

这个如果深入扩展，可以写一大篇！

### 15.1 使用 Playables API 的优势

- Playables API 允许动态动画混合。这意味着对象在**场景**
  可以提供自己的动画。例如，武器、箱子和陷阱的动画可以动态添加到 PlayableGraph 并使用一定的持续时间。
- Playables API 允许您轻松播放单个动画，而无需创建和管理 AnimatorController 资产所涉及的开销。
- Playables API 允许用户动态创建混合图并直接逐帧控制混合权重。
- PlayableGraph 可以在运行时创建，根据需要添加可播放节点。与启用和禁用节点的巨大“一刀切”图不同，PlayableGraph 可以进行定制以适应当前情况的要求。

### 15.2 使用注意事项

在短平快的开发上，基本不需要用到 Playables API。Animator 就基本够用了。

Playables API 灵活度很高，但是有一定开发门槛和学习成本。

除非是动作游戏，射击游戏等有丰富的动画需求的项目，Animator无法满足需求，或者项目有高度定制动画需求倾向，或者动画性能瓶颈，才会去基于 Playables API 去定制针对项目的动画系统。

### 15.3 Animator Controller 在 Playable Graph 的表现

[What Is Animation Pose？](https://link.zhihu.com/?target=https%3A//forum.unity.com/threads/what-is-animation-pose-playable.895379/)

> AnimationPose 实际上是一些用本机代码实现的内部可玩对象。
> 我的猜测是它存储默认的动画姿势。AnimatorController 具有此功能，当某些动画缺少某些骨骼时，它会为这些骨骼使用称为默认姿势的东西。启用 Animator 时对默认姿势进行采样。

### 15.4 学习链接

- 可视化插件：[Unity - Manual: The PlayableGraph](https://link.zhihu.com/?target=https%3A//docs.unity3d.com/Manual/Playables-Graph.html)
- [Unity - Manual: Playables API](https://link.zhihu.com/?target=https%3A//docs.unity3d.com/Manual/Playables.html)
- 官方实例：[Unity - Manual: Playables-Examples](https://link.zhihu.com/?target=https%3A//docs.unity3d.com/cn/2023.2/Manual/Playables-Examples.html)
- [Playable API：定制你的动画系统](https://link.zhihu.com/?target=https%3A//mp.weixin.qq.com/s%3F__biz%3DMzkyMTM5Mjg3NQ%3D%3D%26mid%3D2247535622%26idx%3D1%26sn%3Db96a2d8ac55b49e74261d91bbffa944c%26source%3D41%23wechat_redirect)
- [Playable API_弹吉他的小刘鸭的博客-CSDN博客](https://link.zhihu.com/?target=https%3A//blog.csdn.net/alexhu2010q/article/details/113921119)

跟着sample整个学习下来的感受是，就一个 PlayableBehaviour 比较有新意，抽象好了图的生命周期（OnGraphStart、OnGraphStop、OnPlayableCreate、OnPlayableDestroy、PrepareFrame），可以用来重写实现自定义逻辑。

回想了一下，TimeLine也是基于这个去实现的。[曾志伟：【Unity动画】Timeline 笔记](https://zhuanlan.zhihu.com/p/488738592)

## 16. [Animator IK](https://link.zhihu.com/?target=https%3A//docs.unity3d.com/ScriptReference/MonoBehaviour.OnAnimatorIK.html)

> IK (inverse kinematics) 反向动力学，用来解决模型动作跟随问题。
> 比如人物骑在一个马上面，手要随着马律动
> Unity提供OnAnimatorIK() 回调，用来设置IK位置和权重，IK支持左右脚和左右手

```csharp
  public enum AvatarIKGoal{
    LeftFoot,
    RightFoot,
    LeftHand,
    RightHand,
  }
```

条件：

- Model的Animation Type设置为Humanoid。
- 回调方法OnAnimatorIK(int layerIndex)所在脚本[挂载](https://link.zhihu.com/?target=https%3A//so.csdn.net/so/search%3Fq%3D%E6%8C%82%E8%BD%BD%26spm%3D1001.2101.3001.7020)的游戏对象上的Animator文件中的层，需要打开IK Pass设置

## 17. [Animator.MatchTarget](https://link.zhihu.com/?target=https%3A//docs.unity3d.com/cn/2023.2/ScriptReference/Animator.MatchTarget.html)

通常在游戏中可能出现以下情况：角色必须以某种方式移动，使得手或脚在某个时间落在某个地方。例如，角色可能需要跳过踏脚石或跳跃并抓住顶梁。

```csharp
using UnityEngine;
using System;

[RequireComponent(typeof(Animator))]
public class TargetCtrl : MonoBehaviour {
    protected Animator animator;

    //the platform object in the scene
    public Transform jumpTarget = null;
    void Start () {
        animator = GetComponent<Animator>();
    }

    void Update () {
        if(animator) {
            if(Input.GetButton("Fire1"))         
                animator.MatchTarget(jumpTarget.position, jumpTarget.rotation, AvatarTarget.LeftFoot,
                                                       new MatchTargetWeightMask(Vector3.one, 1f), 0.141f, 0.78f);
        }       
    }
}
```

自动调整`GameObject`的位置和旋转。

调整`GameObject`的位置和旋转，以便当前状态处于指定的进度时，AvatarTarget 到达 matchPosition。目标匹配仅适用于基础层（索引 0）。 一次只能排队一个匹配目标，并且必须等待第一个匹配目标完成，否则将丢弃目标匹配。 如果调用[MatchTarget](https://link.zhihu.com/?target=https%3A//docs.unity3d.com/cn/2023.2/ScriptReference/Animator.MatchTarget.html)的开始时间小于剪辑的当前标准化时间并且剪辑可以循环，[MatchTarget](https://link.zhihu.com/?target=https%3A//docs.unity3d.com/cn/2023.2/ScriptReference/Animator.MatchTarget.html)将调整时间以匹配下一个剪辑循环。例如：开始时间 = 0.2，当前标准化时间 = 0.3，则开始时间将为 1.2。必须启用[Animator.applyRootMotion](https://link.zhihu.com/?target=https%3A//docs.unity3d.com/cn/2023.2/ScriptReference/Animator-applyRootMotion.html)MatchTarget 才会有效。

## 18. 性能优化

[角色模型性能优化](https://link.zhihu.com/?target=https%3A//docs.unity3d.com/cn/2023.2/Manual/ModelingOptimizedCharacters.html)

- 导入人形动画时，如果不需要 IK（反向动力学）目标或手指动画，请使用 Avatar 遮罩 (class-AvatarMask) 将它们移除。
- 实现一个小的 AI 层来控制 Animator。您可以让它为 OnStateChange、OnTransitionBegin 和其他事件提供简单回调。
- 并禁用[蒙皮网格渲染器的](https://link.zhihu.com/?target=https%3A//docs.unity3d.com/cn/2023.2/Manual/class-SkinnedMeshRenderer.html)**Update When Offscreen**属性。这样即可在角色不可见时让 Unity 不必更新动画

## 19. 重定向人形动画

[重定向人形动画 - Unity 手册](https://link.zhihu.com/?target=https%3A//docs.unity3d.com/cn/2023.2/Manual/Retargeting.html)

## 杂

### 问题1 人物手部与目标位点匹配的偏移问题

> 由于射线检测位置是从人物的中心，而高度我们只能获取到BoxCollider的Size高度，因此从中心到人物左手，从Box顶部到手真正需要放的位置，**我们使用了两个偏移量保证左手位置的正确**

### 问题2 动画状态机，多个trigger同时满足，如何选择想要的transtion

> \1. 自己维护好 Trigger 列表，如果我们的实际需求中，不存在需要多个 Trigger 同时被触发的情况，那么记得在设置新的 Trigger 之前（当然也可以考虑优先级和权重值）将其他已经设置过但是还没有被 Animator 应用的 Trigger Reset 掉。

### 3 状态机分层过多，所有层无论是否需要参与运算都会同时运行，存在性能浪费。

### 问题4 角色被隐藏后，恢复显示，状态异常问题

角色被隐藏后，状态机也完全停止了，这个时候对状态机的参数修改会失效，因此需要一个列表用来记录需要恢复的参数。

### 5 Optimize Transform Hierarchy

Hierarchy上的一个选项，Optimize Transform Hierarchy，可以删除transform节点，减少CPU计算，这个优化可以在CPU瓶颈下，进行优化

[AnimatorUtility.OptimizeTransformHierarchy](https://link.zhihu.com/?target=https%3A//docs.unity3d.com/ScriptReference/AnimatorUtility.OptimizeTransformHierarchy.html)

> 此函数将删除 GameObject 下的所有变换层次结构，动画师将直接将变换矩阵写入皮肤网格矩阵，从而节省大量 CPU 周期。
> 您可以选择提供变换名称列表，此函数将在 GameObject 下创建这些变换的扁平层次结构。
> 在运行时调用此函数将重新初始化动画器

## 参考

[Randy：学习笔记 --- Unity动画系统](https://zhuanlan.zhihu.com/p/105029905)

[Randy：当3dMax遇上Unity3d---模型导入的前后你需要注意的地方](https://zhuanlan.zhihu.com/p/56413668)

[大智：Unity动画系统详解3：如何播放、切换动画？](https://zhuanlan.zhihu.com/p/144912096)

[关于 Animator.SetTrigger 的一些迷思](https://link.zhihu.com/?target=https%3A//7dot9.com/2015/07/21/%E5%85%B3%E4%BA%8Eanimator-settrigger%E7%9A%84%E4%B8%80%E4%BA%9B%E8%BF%B7%E6%80%9D/)

[UWA学堂 | Unity和Unreal游戏引擎的从业者学习交流平台](https://link.zhihu.com/?target=https%3A//edu.uwa4d.com/lesson-detail/213/1167/1%3FisPreview%3D0)

[炉石不传说：Unity动画文件Animation的压缩和优化总结](https://zhuanlan.zhihu.com/p/353402448)

[【Unity游戏开发】初探Unity动画优化 - 马三小伙儿 - 博客园](https://link.zhihu.com/?target=https%3A//www.cnblogs.com/msxh/p/14090805.html)

[Unity动画优化](https://link.zhihu.com/?target=https%3A//blog.csdn.net/TracyZly/article/details/79991593)

[R.xiaohaha：Unity动画系统设计介绍](https://zhuanlan.zhihu.com/p/379090845)

[Randy：学习笔记 --- Unity动画系统](https://zhuanlan.zhihu.com/p/105029905)

[动画常见问题解答 - Unity 手册](https://link.zhihu.com/?target=https%3A//docs.unity3d.com/cn/2023.2/Manual/MecanimFAQ.html)

[【Unity动画系统】汇总篇 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/492136094)
