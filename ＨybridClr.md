# HybridCLR

# 总结

1.unity工作原理：AOT user dll（c++） <=> AOT CLR

2.HybridCLR工作原理：AOT user dll （c++） + hotfix dll（CLI） <=> （AOT + Interpreter）CLR

3.HybridCLR解决的问题：

​	a.在unity使用IL2Cpp打包时，进行dll裁切

​	b.裁切后，我们所以无法完整的解释hofix dll，这是由于AOT的泛型限制

​	c.HybridCLR的专利技术Interpreter解决了该问题

## 简介

HybridCLR(代号wolong)是一个**特性完整、零成本、高性能、低内存**的**近乎完美**的Unity全平台原生c#热更方案。

HybridCLR扩充了il2cpp的代码，使它由纯[AOT (opens new window)](https://en.wikipedia.org/wiki/Ahead-of-time_compilation)runtime变成‘AOT+Interpreter’ 混合runtime，进而原生支持动态加载assembly，使得基于il2cpp backend打包的游戏不仅能在Android平台，也能在IOS、Consoles等限制了JIT的平台上高效地以**AOT+interpreter**混合模式执行。从底层彻底支持了热更新。

## 特性

- 特性完整。 近乎完整实现了[ECMA-335规范 (opens new window)](https://www.ecma-international.org/publications-and-standards/standards/ecma-335/)，除了 下文中"限制和注意事项" 之外的特性都支持。
- 零学习和使用成本。 HybridCLR将纯AOT runtime增强为完整的runtime，使得热更新代码与AOT代码无缝工作。脚本类与AOT类在同一个运行时内，可以随意写继承、反射、多线程(volatile、ThreadStatic、Task、async)之类的代码。不需要额外写任何特殊代码、没有代码生成，也没有什么特殊限制。
- 执行高效。实现了一个极其高效的寄存器解释器，所有指标都大幅优于其他热更新方案。[性能测试报告(opens new window)](https://focus-creative-games.github.io/hybridclr/benchmark/#性能测试报告)
- 内存高效。 热更新脚本中定义的类跟普通c#类占用一样的内存空间，远优于其他热更新方案。[内存占用报告(opens new window)](https://focus-creative-games.github.io/hybridclr/benchmark/#内存占用报告)
- 原生支持hotfix修复AOT部分代码。几乎不增加任何开发和运行开销。

## 工作原理

HybridCLR从mono的[hybrid mode execution (opens new window)](https://developpaper.com/new-net-interpreter-mono-has-arrived/)技术中得到启发，为unity的il2cpp之类的AOT runtime额外提供了interpreter模块，将它们由纯AOT运行时改造为"AOT + Interpreter"混合运行方式。

更具体地说，HybridCLR做了以下几点工作：

- 实现了一个高效的元数据(dll)解析库
- 改造了元数据管理模块，实现了元数据的动态注册
- 实现了一个IL指令集到自定义的寄存器指令集的compiler
- 实现了一个高效的寄存器解释器
- 额外提供大量的instinct函数，提升解释器性能
- 提供hotfix AOT的支持

## 兼容性

- 支持所有il2cpp支持的平台。目前测试支持 PC(Win32和Win64)、macOS(x86、x64、Arm64)、Android(armv7、armv8)、iOS(64bit)、NS(64bit)、WebGL(有少量bug)平台，剩余平台有待测试。
- 已经支持Unity 2019、2020、2021全系列LTS版本
- 测试过大量游戏常见库，未发现跟il2cpp原生兼容但使用HybridCLR后不兼容性的库。只要能在il2cpp backend下工作的库都可以在HybridCLR下正常工作。甚至那些与il2cpp因为AOT问题不兼容的库，现在因为HybridCLR对il2cpp的能力扩充，反而可以正常运行了。

## 稳定性状况

目前PC(x86及x64)、macOS(x86、x64、Arm64)、Android(arm v7及v8)、iOS(64bit) 可稳定使用。

自2022.3.33开源以来，已经有数百个大中小型商业游戏项目完成接入，已超过[8个中重度商业项目](https://focus-creative-games.github.io/hybridclr/business_games/)Android+iOS双平台正式上线，以及更多项目已经上线对外测试，同时在线上有超过3个月的稳定表现。

目前版本为release candidate版本，相关工作流工具已经成熟，预计于**10月份发布正式版本**。

# 安装HybridCLR

## 安装前预备工作

- 安装 2019.4.40、2020.3.21、2021.3.0或更高版本。新手强烈推荐先用2020.3.33版本熟悉热更新后，再尝试自己项目的版本。由于Installer使用路径中的版本号来判定Unity版本，请确保安装路径中包含版本号，例如 `d:\Unity2020.3.33`。
- 由于使用il2cpp backend，要求安装Unity时必须包含il2cpp 组件。如果未安装，请自行在UnityHub中安装。
- 安装相关开发SDK及IDE
  - Win下需要安装`visual studio 2019`或更高版本。安装时必须选中 `使用c++的游戏开发` 这个组件
  - Mac下需要安装xcode较新版本，例如`xcode 13.4.1 macos 12.4`。最小支持版本是哪个我们未仔细验证过。
- 安装git

## 安装hybridclr-package安装HybridCLR package

从git url安装 `com.focus-creative-games.hybridclr_unity` [gitee（推荐） (opens new window)](https://gitee.com/focus-creative-games/hybridclr_unity)或[github (opens new window)](https://github.com/focus-creative-games/hybridclr_unity)package。 不熟悉从url安装package的请看[install from giturl (opens new window)](https://docs.unity3d.com/Manual/upm-ui-giturl.html)。

由于国内网络原因，在unity中可能遇到网络异常而无法安装。你可以先把 `com.focus-creative-games.hybridclr_unity` clone或者下载到本地，然后再 [install from disk (opens new window)](https://docs.unity3d.com/Manual/upm-ui-local.html)。

或者更简单一点的做法，下载到本地后，将仓库文件夹目录改名为`com.focus-creative-games.hybridclr_unity`，直接复制到你们项目的`Packages`目录下即可。

## 初始化HybridCLR

为了减少package自身大小，有一些文件需要从Unity Editor的安装目录复制。因此安装完插件后，还需要一个额外的初始化过程。

点击菜单 `HybridCLR/Installer...`，弹出安装界面。如果安装界面没有错误或者警告，则说明il2cpp路径设置正常，否则需要你手动选择正确的il2cpp目录。 点击`install`按钮完成安装。

如果安装失败，最常见原因为git未安装，或者安装git后未重启Unity Editor。如果你确信安装了git，cmd中也确实能运行git，则尝试重启电脑。

## Unity版本相关特殊操作

### Unity 2021

对于使用Unity 2021版本（2019、2020不需要）打包`iOS平台`(其他平台不需要)的开发者，由于HybridCLR需要裁减后的AOT dll，但Unity Editor未提供公开接口可以复制出target为iOS时的AOT dll，故必须使用修改后的UnityEditor.CoreModule.dll覆盖Unity自带的相应文件。

具体操作为将 `HybridCLRData/ModifiedUnityAssemblies/2021.3.x/UnityEditor.CoreModule-{Win,Mac}.dll` 覆盖 `{Editor安装目录}/Editor/Data/Managed/UnityEngine/UnityEditor.CoreModule`，具体相关目录有可能因为操作系统或者Unity版本而有不同。

**由于权限问题，该操作无法自动完成，需要你手动执行复制操作。**

`UnityEditor.CoreModule.dll` 每个Unity小版本都不相同，我们目前暂时只提供了2021.3.1、2021.3.6版本，如需其他版本请自己手动制作，详情请见 [修改Unity编辑器相关dll](https://focus-creative-games.github.io/hybridclr/modify_unity_dll/)。

### Unity 2019

为了支持2019，需要修改il2cpp生成的源码，因此我们修改了2019版本的il2cpp.exe工具。故Installer的安装过程多了一个额外步骤：将 `{package}/Data/ModifiedUnityAssemblies/2019.4.40/Unity.IL2CPP.dll` 复制到 `{package}/Data/LocalIl2CppData/il2cpp/build/deploy/net471/Unity.IL2CPP.dll`

**注意，该操作在Installer安装时自动完成，不需要手动操作。**

由于时间有限，目前只制作了2019.4.40的`Unity.IL2CPP.dll`文件，将来会补充更多版本，如需其他版本请自己手动制作，详情请见 [修改Unity编辑器相关dll](https://focus-creative-games.github.io/hybridclr/modify_unity_dll/)，或者找我们的商业技术支持。

## 安装原理

HybridCLR安装过程主要包含这几部分：

- 替换libil2cpp代码
- 对Unity Editor的少量改造

### 替换libil2cpp代码

原始的libil2cpp代码是静态CLR，需要替换成改造后的libil2cpp才能支持热更新。改造后的libil2cpp由两部分构成

- [il2cpp_plus(opens new window)](https://github.com/focus-creative-games/il2cpp_plus)
- [hybridclr(opens new window)](https://github.com/focus-creative-games/hybridclr)

il2cpp_plus仓库为对原始libil2cpp作了少量修改以支持动态**register**元数据的版本（改了几百行代码）。这个仓库与原始libil2cpp代码高度 相似。2019-2021各有一个对应分支。

hybridclr为解释器部分的核心代码，包含元数据加载、代码transform(编译)、代码解释执行。所有Unity版本共享同一套hybridclr代码。

[merge_hybridclr_dir](https://focus-creative-games.github.io/img/hybridclr/merge_hybridclr_dir.jpg)

根据与你的Unity版本匹配的il2cpp_plus分支(详情见[supported_unity_versions](https://focus-creative-games.github.io/hybridclr/supported_unity_versions/))和hybridclr制作出最终版本的libil2cpp后，有两种安装方式：

#### 全局安装

直接替换Editor安装目录的libil2cpp目录(Win下为{editor}/Data/il2cpp/libil2cpp，Mac类似)。优点是简单，缺点是会影响其他不使用 hybridclr的项目，而且可能遇到目录权限问题。

#### 项目本地安装

Unity允许使用环境变量`UNITY_IL2CPP_PATH`自定义`il2cpp`的位置。因此hybridclr_unity包中，将进程环境变量`UNITY_IL2CPP_PATH`指向`{project}/HyridCLRData/LocalIl2CppData-{platform}/il2cpp`。il2cpp目录从Unity Ediotr安装目录复制，然后替换`il2cpp/libil2cpp`目录为修改后lil2cpp。

为什么需要创建上层的`LocalIl2CppData-{platform}`目录，而不是只创建il2cpp呢？实测发现仅仅指定il2cpp目录位置是不够的，打包时Unity隐含假设了il2cpp同级有一个`MonoBleedingEdge`目录，所以创建了上级目录，将il2cpp及MonoBleedingEdge目录都复制过来。

因为不同平台Editor自带的il2cpp目录略有不同，LocalIl2CppData要区分platform。

## 注意事项

由于 Unity 的缓存机制，更新 HybridCLR 后，一定要清除 Library\Il2cppBuildCache 目录，不然打包时不会使用最新的代码。如果你使用Installer来自动安装或者更新HybridCLR，它会自动清除这些目录，不需要你额外操作。

# 项目设置

安装完hybridclr_unity包后，需要对项目进行AOT/热更新 assembly拆分，并且正确设置相关配置参数。

## 配置PlayerSettings

- 关闭增量式GC(Use Incremental GC) 选项。因为目前不支持增量式GC
- il2cpp backend 切换为 `il2cpp`
- Api Compatability Level 切换为 `.Net 4 or .Net Framework` (打包时可以使用.net standard，但使用脚本Compile热更新dll时必须切换到`.Net 4.x or .Net Framework`)

## 热更新模块拆分

很显然，项目必须拆分为AOT（即编译到App包内）和热更新 assembly，才能进行热更新。HybridCLR对于 怎么拆分程序集并无任何限制，甚至你将AOT或者热更新程序集放到第三方工程中也是可以的。

常见的拆分方式有几种：

- 使用Unity支持的Assembly Definition将整个项目拆分为多个程序集，Assembly-CSharp作为AOT程序集，不引用任何热更新程序集的代码
- 将AOT部分拆分为一个或多个程序集，Assembly-CSharp作为热更新程序集，同时还有其他0-N个热更新程序集。

无论哪种拆分方式，正确设置好程序集之间的引用关系即可

## 配置 HybridCLRGlobalSettings.asset

HybridCLRGlobalSettings是HybridCLR的Editor配置文件，详细文档可见 [hybridclr_unity包介绍](https://focus-creative-games.github.io/hybridclr/hybridclr_unity/)。这是个单例配置，有且只能用一个。

如果未创建，project窗口中右键`Create/HybridCLR/GlobalSettings`创建配置文件。

对于项目中的热更新程序集，如果是assembly definition(asmdef)定义的程序集，加入 `hotUpdateAssemblyDefinitions`列表，如果是普通dll，则将程序集名字（不包含'.dll'后缀，如Main、Assembly-CSharp）加入`hotUpdateAssemblies`即可。这两个列表是等价的，不要重复添加，否则会报错。

**至此完成热更新相关的所有设置**。

# AOT泛型处理

clr中有两类泛型特性：泛型类型和泛型函数。泛型是c#中使用极其广泛的特性。即使一个没有明显包含泛型的用法，可能隐含了泛型相关的定义或者操作。例如 int[]隐含就实现 IEnemrable<int> 之类的接口。又如 为async生成状态机代码时，也会隐含生成一些对System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<!T>::AwaitUnsafeOnCompleted<!!T1,!!T2> 之类的泛型代码。

## 其他资料

也可以参考[视频 (opens new window)](https://www.bilibili.com/video/BV1Wf4y1o7yu/)。

## AOT泛型的问题

泛型类型本身只是元数据，内存中可以动态创造出任意泛型类型的实例化，无论是AOT泛型还是解释器泛型，但泛型函数（包括泛型类的普通成员函数）则情况有点不同。

解释器泛型函数没有任何限制，但AOT泛型函数则遇到一个严重的问题：由于泛型函数的原始函数体元数据在il2cpp翻译后已经丢失，理论不可能根据已有的c++泛型函数指针为一个新的泛型类型产生对应泛型实例化函数。

对于一些特殊的AOT泛型，HybridCLR作了特殊处理，没有限制：

- 泛型数组，包括多维数组
- 泛型delegate
- 泛型Nullable类型

但显然不可能对每个AOT泛型类特殊处理。因此，如果你在热更新脚本里定义了个值类型：



```csharp
struct MyVector2
{
    public int x;
    public int y;
}
```

你想在脚本中创建`new List<MyVector2>()` 这样的类型，通常来说是不可能的，因为虽然HybridCLR可以创建出`List<MyVector2>`类型的元数据，但无法获得泛型函数`List<MyVector>.ctor`（cli中构造函数名称）的实现，导致无法创建对象。

本质上，因为AOT翻译导致原始IL指令元数据的缺失，进而无法创建出AOT泛型函数的实例。如果原先在AOT中已经生成对应泛型函数的代码，例如假设你在AOT中用过`List<int>.Count`，则在热更新部分可以使用。

泛型类，尤其是泛型容器List、Dictionary之类在代码中使用如此广泛，如果因为AOT限制，导致List<HotUpdateType>都不能运行，那游戏热更新的代码受限就太大了。幸运的是，HybridCLR使用两类技术彻底解决了这个问题：

- 基于il2cpp的泛型共享机制
- 基于补充元数据的泛型函数实例化技术（HybridCLR的专利技术)

## il2cpp的泛型共享机制

il2cpp为了避免泛型代码膨胀，节约内存，在保证代码逻辑正确性的情况下对于一些能够共享代码，只生成一份代码。为此引入一个概念叫**泛型代码共享** [Generic Sharing (opens new window)](https://blog.unity.com/technology/il2cpp-internals-generic-sharing-implementation),此技术更早则源于mono。CLR中也有同样的概念，CLR认为所有引用类型实参都一样，所以可以代码共享，例如，为List<String>方法编译的代码可以直接用于List<Stream>方法，这是因为所有引用类型实参/变量只是指向托管堆的一个8字节指针（这里假设64位系统），但是对于值类型，则必须每种类型都进行代码生成，因为值类型大小不定。

以List<T> 举例：

- 可以使用AOT中使用过的任何List的实例化类型。例如你在AOT里用过List<vector3>,则热更新里也可以用
- 可以使用任意List<HotUpdateEnum>。 只需要你在AOT里实例化某一个List<相同size的枚举类型>。
- 可以使用任意引用类型的泛型参数List<HotUpdateClass>。 只需要你在AOT里实例化过 List<object>(或任意一个引用泛型参数如List<string>)

注意！！！il2cpp泛型共享机制 **不支持** List<热更新值类型>。因为值类型无法泛型共享，而热更新值类型不可能提前在AOT里泛型实例化。这个限制由下一节`基于补充元数据的泛型函数实例化技术`彻底解决。不过即使没有这个限制，对于AOT值类型，能提前泛型实例化，可以大幅提升性能（毕竟不用解释执行了）。后续会有工具帮助自动收集热更新模块中的泛型实例，尽量让它提前AOT实例化。

### il2cpp中值类型不支持泛型共享的原因

不同size的值类型大小不同，不能共享，这容易理解，但为何相同size的值类型不能像class那样泛型共享呢？主要有两个原因：

#### 值类型就算大小相同，如果对齐方式不一样，作为其他类的子字段时，最终所在的类的内存大小和布局可能不同

举例



```csharp
struct A // size = 4, alignment = 2
{
    short x;
    short y;
};

struct B // size = 4，alignment = 4
{
    int x;
};

struct GenericDemo<T>
{
    short x;
    T v;

    public T GetValue() => v;
};
```

`GenericDemo<A>` size=6，alignment=2，字段v在类中偏移为2；而 `GenericDemo<B>` size=8，alignment=4， v字段在类中偏移为4。显然对于GetValue函数，由于v的偏移不同，是不太可能生成一套相同的c++代码对这两个类都能正确工作。

#### ABI 兼容问题

相同大小的结构体，在[x64 ABI (opens new window)](https://docs.microsoft.com/zh-cn/cpp/build/x64-software-conventions?redirectedfrom=MSDN&view=msvc-170)是等效的，可以用同等大小的结构体来作共享泛型实例化。但在[arm64 ABI (opens new window)](https://docs.microsoft.com/zh-cn/cpp/build/arm64-windows-abi-conventions?view=msvc-170)却是不行的。

举例

`struct IntVec3 { int32_t x, y, z; }` 和 `struct FloatVec3 { float x, y, z}` 它们虽然大小都是12，但作为函数参数传递时，传参方式是不一样的：

- IntVec3 以引用的方式传参
- FloatVec3 的三个字段，分别放到三个浮点寄存器里

这个是结构体无法泛型共享的另一个关键原因

### 共享类型计算规则

假设泛型类 T 的共享类型为generic reduce type， 计算规则如下。

#### 非枚举的值类型

reduce type为自身。如int的reduce type为int

#### 枚举类型

reduce type为 underlying type与它相同的枚举。例如



```csharp
enum MyEnum 
{
    A = 1,
}
enum MyEnum2 : sbyte
{
    A = 10,
}
```

由于enum的默认underlying type是int，因此MyEnum的reduce type为 Int32Enum,MyEnum2的reduce type为 SByteEnum。注意，CLI中并没有Int32Enum、SByteEnum这些类型，需要你的AOT中提前创建一个这样的枚举类型。

#### class引用类型

reduce type为 object

#### 泛型类型

GenericType<T1,T2,...> 如果是class类型则reduce type为object，否则reduce type为 GenericType<ReduceType<T1>, ReduceType<T2>...>。

例如

- Dictionary<int, string>的reduce type为object。
- YourValueType<int, string>的reduce type为YourValueType<int,object>

### 泛型函数的共享泛型函数 计算规则

对于 `Class<C1, C2, ...>.Method<M1, M2, ...>(A1, A2, ...)` 的AOT泛型函数为 `Class<reduce(C1), reduce(C2), ...>.Method<reduce(M1), reduce(M2), ...>(reduce(A1), reduce(A2), ...)`

- `List<string>.ctor` 对应共享函数为 `List<object>.ctor`
- `List<int>.Add(int)` 对应共享函数为 `List<int>.Add(int)`
- `YourGenericClass<string, int, List<int>>.Show<string, List<int>, int>(ValueTuple<int, string>, string, int)` 的共享函数为 `YourGenericClass<object, int, object>.Show<object, object, int>(ValueTuple<int, object>, object, int)`

一个很有用的小技巧，RefTypes.cs 中添加对应AOT泛型函数的调用时，对于函数参数，通过 default(T) 来指定这个参数。

### c# async与IEnumerable之类语法糖机制引发的AOT泛型问题

编译器可能为会async之类的复杂语法糖生成隐含的AOT泛型引用。故为了让这些机制能够正常工作，也必须解决它们引发的AOT泛型实例化问题。

以async为例，编译器为async生成了若干类及状态机及一些代码，这些隐藏生成的代码中包含了对多个AOT泛型函数的调用，常见的有：

- `void AsyncTaskMethodBuilder::Start<TStateMachine>(ref TStateMachine stateMachine)`
- `void AsyncTaskMethodBuilder::AwaitUnsafeOnCompleted<TAwaiter, TStateMachine>(ref TAwaiter awaiter, ref TStateMachine stateMachine)`
- `void AsyncTaskMethodBuilder::SetException(Exception exception)`
- `void AsyncTaskMethodBuilder::SetResult()`
- `void AsyncTaskMethodBuilder<T>::Start<TStateMachine>(ref TStateMachine stateMachine)`
- `void AsyncTaskMethodBuilder<T>::AwaitUnsafeOnCompleted<TAwaiter, TStateMachine>(ref TAwaiter awaiter, ref TStateMachine stateMachine)`
- `void AsyncTaskMethodBuilder<T>::SetException(Exception exception)`
- `void AsyncTaskMethodBuilder<T>::SetResult(T result)`

如果遇到这些AOT泛型实例化缺失错误，使用标准的泛型AOT的实例化规则去解决这些问题即可。

另外，由于c#编译器对release模式下生成的状态机是ValueType类型，导致无法泛型共享，但debug模式下生成的状态机是class类型，可以泛型共享。因此如果**未使用基于补充元数据的泛型函数实例化技术**，则为了能够让热更新中使用async语法，`使用脚本编译dll时，务必加上`scriptCompilationSettings.options = ScriptCompilationOptions.DevelopmentBuild;`代码，这样编译出的状态机是class类型，在热更新代码中能正常工作。如果已经使用此技术，由于彻底支持AOT泛型，则对编译方式无限制。

### 代码裁剪

由于unity默认的代码裁剪规则，如果你未在代码中使用过，它是不会为你生成这些泛型共享函数的。故为了让 `List<YourHotUpdateClass>` 的各个函数能够正确调用。你要确保`List<object>`（其实`List<string>`也行）必须在AOT中已经提前调用过。

理论上，每个泛型函数（包括泛型类的成员函数）都需要在AOT中提前引用过（不必是真正运行，只需要代码中假装调用过），但这么写也太麻烦了。根据Unity的类型裁剪规则，类型的public函数会默认被保留，所以你一般只用在AOT中`new List<int>`这样就行了。

为了方便大家使用，我们会提供一个默认的 `RefTypes.cs`(这个名字有极大误导性，准确说叫GenericMethodInstantiate更合适)文件，它已经包含了对常见泛型类型的实例化，你也可以自己修改或者扩充它。

### AOT泛型实例化错误的处理示例

#### 示例1

错误日志



```csharp
MissingMethodException: AOT generic method isn't instantiated in aot module 
  System.Collections.Generic.IEnumerable'1[System.Byte] 
  System.Linq.Enumerable::Skip<System.Byte>(System.Collections.Generic.IEnumerable'1[System.Byte, System.Init32])
```

你在RefType里加上 `IEnumerable.Skip<byte>(IEnumerable<byte>, int)`的调用。



```csharp
class RefTypes
{
  public void MyAOTRefs()
  {
      IEnumerable.Skip<byte>((IEnumerable<byte>)null, 0);
  }
}
```

#### 示例2

错误日志



```csharp
MissingMethodException: AOT generic method isn't instantiated in aot module 
  void System.Collections.Generic.List<System.String>.ctor()
```

你在RefType里加上 `List<string>.ctor()` 的调用，即 `new List<string>()`。由于**泛型共享机制**，你调用 `new List<object>()` 即可。



```csharp
class RefTypes
{
  public void MyAOTRefs()
  {
      new List<object>();
  }
}
```

#### 示例3

错误日志



```csharp
MissingMethodException: AOT generic method isn't instantiated in aot module 
    void System.ValueType<System.Int32, System.String>.ctor()
```

注意！值类型的空构造函数没有调用相应的构造函数，而是对应 initobj指令。实际上你无法直接引用它，但你只要强制实例化这个类型就行了，preserve这个类的所有函数，自然就会包含.ctor函数了。

实际中你可以用强制装箱 `(object)(default(ValueTuple<int, object>))`。



```csharp
class RefTypes
{
  public void MyAOTRefs()
  {
      // 以下两种写法都是可以的
      _ = (object)(new ValueTuple<int, object>());
      _ = (object)(default(ValueTuple<int, object>));
  }
}
```

#### 示例4

错误日志



```csharp
MissingMethodException: AOT generic method isn't instantiated in aot module 
  void YourGenericClass<System.Int32, List<string>>.Show<List<int>, int>(List<string>, ValueTuple<int, string>, int)
```



```csharp
class RefTypes
{
  public void MyAOTRefs()
  {
      YourGenericClass<int, object>.Show<object,int>(default(object), default(ValueTuple<int,object>), default(int));
  }
}
```

#### 示例5

错误日志



```csharp
MissingMethodException: AOT generic method isn't instantiated in aot module 
  System.Void System.Runtime.CompilerService.AsyncVoidMethodBuilder::Start<UIMgr+ShowUId__2>(UIMgr+<ShowUI>d__2&)
```



```csharp
class RefTypes
{
  public void MyAOTRefs()
  {
      var builder = new System.Runtime.CompilerService.AsyncVoidMethodBuilder();
      IAsyncStateMachine asm = default;
      builder.Start(ref asm);
  }
}
```

#### 示例 6

```
AOT generic method not instantiated in aot module. System.Int32 System.Tuple`4[System.Int32,System.Int32,System.Int32,System.Int32]::get_Item2()
```



```csharp
class RefTypes
{
  public void MyAOTRefs()
  {
      var y = default(Tuple<int,int,int,int>).Item2;
      // 或者如下面。总之要调用Item2属性
      default(Tuple<int,int,int,int>).Item2.ToString();
  }
}
```

## 基于补充元数据的泛型函数实例化技术（HybridCLR的专利技术)

既然AOT泛型函数无法实例化的问题本质上是il2cpp翻译造成的元数据缺失的问题，那解决思路也很简单，补充上原始元数据那就能正常实例化了。使用`HybridCLRApi.LoadMetadataForAOTAssembly`函数为AOT的assembly补充对应的元数据。

注意，当前要求补充的dll与打包时裁剪后的dll精确一致，因此必须使用build过程中生成的裁剪后的dll，则不能直接复制原始dll，这个限制将来可能会去掉。 我们在HybridCLR_BuildProcessor_xxx里添加了处理代码，这些裁剪后的dll在打包时自动被复制到 {项目目录}/hybridclrData/AssembliesPostIl2CppStrip/{Target} 目录。

你只要在使用AOT泛型前调用即可（只需要调用一次），理论上越早加载越好。实践中比较合理的时机是热更新完成后，或者热更新dll加载后但还未执行任何代码前。如果补充元数据的dll作为额外数据文件也打入了主包，则主工程启动时加载更优。如果AOT泛型未注册相应的泛型元数据，则退回到il2cpp的泛型共享机制。

基于补充元数据的泛型函数实例化技术虽然相当完美，但毕竟实例化的函数以解释方式执行，如果能提前在AOT中泛型实例化，可以大幅提升性能。 所以推荐对于常用尤其是性能敏感的泛型类和函数，提前在AOT中实例化。后续我们也会提供工具帮助自动扫描收集相应的泛型实例。

以下代码来自 [HybridCLR_trial (opens new window)](https://github.com/focus-creative-games/hybridclr_trial)。



```csharp
    /// <summary>
    /// 为aot assembly加载原始metadata， 这个代码放aot或者热更新都行。
    /// 一旦加载后，如果AOT泛型函数对应native实现不存在，则自动替换为解释模式执行
    /// </summary>
    public static unsafe void LoadMetadataForAOTAssembly()
    {
        // 可以加载任意aot assembly的对应的dll。但要求dll必须与unity build过程中生成的裁剪后的dll一致，而不能直接使用原始dll。
        // 我们在BuildProcessor_xxx里添加了处理代码，这些裁剪后的dll在打包时自动被复制到 {项目目录}/HybridCLRData/AssembliesPostIl2CppStrip/{Target} 目录。

        /// 注意，补充元数据是给AOT dll补充元数据，而不是给热更新dll补充元数据。
        /// 热更新dll不缺元数据，不需要补充，如果调用LoadMetadataForAOTAssembly会返回错误
        /// 
        List<string> aotDllList = new List<string>
        {
            "mscorlib.dll",
            "System.dll",
            "System.Core.dll", // 如果使用了Linq，需要这个
            // "Newtonsoft.Json.dll",
            // "protobuf-net.dll",
            // "Google.Protobuf.dll",
            // "MongoDB.Bson.dll",
            // "DOTween.Modules.dll",
            // "UniTask.dll",
        };

        AssetBundle dllAB = LoadDll.AssemblyAssetBundle;
        foreach (var aotDllName in aotDllList)
        {
            byte[] dllBytes = dllAB.LoadAsset<TextAsset>(aotDllName).bytes;
            fixed (byte* ptr = dllBytes)
            {
                // 加载assembly对应的dll，会自动为它hook。一旦aot泛型函数的native函数不存在，用解释器版本代码
                int err = HybridCLR.RuntimeApi.LoadMetadataForAOTAssembly((IntPtr)ptr, dllBytes.Length);
                Debug.Log($"LoadMetadataForAOTAssembly:{aotDllName}. ret:{err}");
            }
        }
    }
```

# 桥接函数

可参考[视频教程(opens new window)](https://www.bilibili.com/video/BV12N4y1T7FZ/)

了解桥接函数HybridCLR的interpreter与AOT之间需要双向函数调用。比如，interpreter调用AOT函数，或者AOT部分有回调函数会调用解释器部分。

AOT部分与解释器部分的参数传递和存储方式是不一样的。比如解释器部分调用AOT函数，解释器的参数全在解释器栈上，必须借助合适的办法才能将解释器的函数参数传递给AOT函数。同样的，解释器无法使用通过办法直接获得AOT回调函数的第x个参数。必须为每一种签名的函数生成对应的桥接函数，来实现解释器与aot部分的双向函数参数传递。

这个操作，虽然可以通过ffi之类的库来完成，但运行时使用这种方式，函数调用的成本过高，因此合理的方式仍然是提前生成好这种双向桥接函数。

**解释器内部调用不需要这种桥接函数**，可以是任意签名。

## 共享桥接函数

不是每一个不同的函数签名都要生成一个桥接函数，大多数签名是可以共享的。例如



```csharp
int Fun1(int a, int b);
int Fun2(object a, long b);
long Fun3(long a, long b);
object Fun4(object a, object b);
```

对于x64和arm64平台, int、long、class类型共享相同的签名。因此以上Fun1-Fun4，它们都可以共享一个 "long (long, long) 签名的桥接函数。跟泛型共享规则类型，算出某个函数签名的共享桥接签名后，生成对应的桥接函数。

具体的共享规则是平台相关的，不同的abi的规则不一样。

桥接函数不同于xlua之类生成的wrap函数，大多数情况下添加了新的aot函数是不需要重新生成MethodBridge函数的。

由于我们目标是手游，主要的CPU为arm v7或者arm v8，而且arm架构的ABI比x64大多数情况下复杂多变很多。 为了避免维护过多平台的成本，以及我们希望在Win平台就能测试出所有桥接函数缺失的情况，我们索性针对32和64位各设计了一个最严格的ABI规则， 分别叫Universal32和Universal64，以及专门对手游64位平台设计了Arm64 ABI。

### Universal32 的共享规则

共享规则对函数参数和返回值均生效。

- bool, int8_t, uint8_t
- int16_t, uint16_t
- int32_t, uint32_t, pointer, ref, object
- int64_t, uint64_t
- float
- double
- ValueType_size_aligment 相同size和aligment的值类型才能共享
- 其他

### Universal64 的共享规则

共享规则对函数参数和返回值均生效。Universal64比Universal32签名规则复杂很多。

- bool, int8_t, uint8_t
- int16_t, uint16_t
- int32_t, uint32_t
- int64_t, uint64_t, pointer, ref, object
- float
- double
- ValueType_size_aligment 相同size和aligment的值类型才能共享
- ValueTypeRef 以引用方式传参
- Vector2(或者叫HFA2 float) (x,y为float类型)
- Vector3(HFA3 float)
- Vector4(FHA4 float)
- Vector2d (HFA2 double) (即x,y为double类型)
- Vector3d(HFA3 double)
- Vector4d(HFA4 double)
- HVA 2
- HVA 3
- HVA 4

### Arm64 的共享规则

- bool, int8_t, uint8_t
- int16_t, uint16_t
- int32_t, uint32_t
- int64_t, uint64_t, pointer, ref, object
- float
- double
- ValueType size (8, 16]
- ValueType size (16, +) 以引用方式传参
- ValueType size (16, +) 以值类型返回值
- Vector2(或者叫HFA2 float) (x,y为float类型)
- Vector3(HFA3 float)
- Vector4(FHA4 float)
- Vector2d (HFA2 double) (即x,y为double类型)
- Vector3d(HFA3 double)
- Vector4d(HFA4 double)
- HVA 2
- HVA 3
- HVA 4

## HybridCLR默认桥接函数集

HybridCLR已经扫描过Unity核心库和常见的第三方库生成了默认的桥接函数集，相关代码文件为 libil2cpp/hybridclr/interpreter/MethodBridge_{abi}.cpp，其中{abi}为Universal32或Universal64。

## 自定义桥接函数集

实践项目中总会遇到一些aot函数的共享桥接函数不在默认桥接函数集中。因此提供了Editor工具，根据程序集自动生成所有桥接函数。 代码参见 [hybridclr_trial (opens new window)](https://github.com/focus-creative-games/hybridclr_trial)项目

相关生成代码在 Editor/HybridCLR/Interpreter目录。菜单命令代码在Editor/HybridCLR/MethodBridgeHelper.cs中。

- 菜单 HybridCLR/MethodBridge/Universal32 生成 MethodBridge_Universal32.cpp。
- 菜单 HybridCLR/MethodBridge/Universal64 生成 MethodBridge_Universal64.cpp。

**注意**!!! 目前扫描工具还不能智能收集泛型类实例的成员函数及泛型函数，因此有可能运行时会出现缺失某些桥接函数，需要手动添加桥接函数相关配置，在 `Editor/HybridCLR/Generators/GeneratorConfig.cs`。目前有两种方式可以添加桥接函数：

- 添加桥接函数所在的类名。添加到 `PrepareCustomGenericTypes`函数中
- 添加桥接函数相同签名的Delegate类型。 添加到 `PrepareCustomGenericTypes`函数中
- 添加桥接函数签名。注意，由于32位和64位的签名计算规则不同，他们的缺失的桥接函数也往往不同，根据是32位还是64位平台，添加到 `PrepareCustomMethodSignatures32` 或 `PrepareCustomMethodSignatures64` 函数中。

以下是示例代码



```csharp
        /// <summary>
        /// 暂时没有仔细扫描泛型，如果运行时发现有生成缺失，先手动在此添加类
        /// </summary>
        /// <returns></returns>
        public static List<Type> PrepareCustomGenericTypes()
        {
            return new List<Type>
            {
                typeof(Dictionary<int, Vector>), // 添加函数所在类名
                typeof(Action<int, string, Vector3>), // 添加函数对应的delegate类型
            };
        }

        /// <summary>
        /// 如果提示缺失桥接函数，将提示缺失的签名加入到下列列表是简单的做法。
        /// 这里添加64位App缺失的桥接函数签名
        /// </summary>
        /// <returns></returns>
        public static List<string> PrepareCustomMethodSignatures64()
        {
            return new List<string>
            {
                "vi8i8", // 添加签名
            };
        }

        /// <summary>
        /// 如果提示缺失桥接函数，将提示缺失的签名加入到下列列表是简单的做法。
        /// 这里添加32位App缺失的桥接函数签名
        /// </summary>
        /// <returns></returns>
        public static List<string> PrepareCustomMethodSignatures32()
        {
            return new List<string>
            {
                "vi4i4", // 添加签名
            };
        }
```
