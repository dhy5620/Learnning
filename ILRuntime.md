# 1、基础

## 介绍

ILRuntime项目为基于C#的平台（例如Unity）提供了一个`纯C#实现`，`快速`、`方便`且`可靠`的IL运行时，使得能够在不支持JIT的硬件环境（如iOS）能够实现代码的热更新

## 优势

同市面上的其他热更方案相比，ILRuntime主要有以下优点：

- 无缝访问C#工程的现成代码，无需额外抽象脚本API
- 直接使用VS2015进行开发，ILRuntime的解译引擎支持.Net 4.6编译的DLL
- 执行效率是L#的10-20倍
- 选择性的CLR绑定使跨域调用更快速，绑定后跨域调用的性能能达到slua的2倍左右（从脚本调用GameObject之类的接口）
- 支持跨域继承
- 完整的泛型支持
- 拥有Visual Studio的调试插件，可以实现真机源码级调试。支持Visual Studio 2015 Update3 以及Visual Studio 2017和Visual Studio 2019

## C# VS Lua

目前市面上主流的热更方案，主要分为Lua的实现和用C#的实现，两种实现方式各有各的优缺点。

Lua是一个已经非常成熟的解决方案，但是对于Unity项目而言，也有非常明显的缺点。就是如果使用Lua来进行逻辑开发，就势必要求团队当中的人员需要同时对Lua和C#都特别熟悉，或者将团队中的人员分成C#小组和Lua小组。不管哪一种方案，对于中小型团队都是非常痛苦的一件事情。

用C#来作为热更语言最大的优势就是项目可以用同一个语言来进行开发，对Unity项目而言，这种方式肯定是开发效率最高的。

Lua的优势在于解决方案足够成熟，之前的C++团队可能比起C#，更加习惯使用Lua来进行逻辑开发。此外借助luajit，在某些情况下的执行效率会非常不错，但是luajit现在维护情况也不容乐观，官方还是推荐使用公版Lua来开发。

如果需要测试ILRuntime对比Lua的性能Benchmark，需要确认以下几点：

- ILRuntime加载的dll文件是`Release`模式编译的
- dll中对外部API的调用都进行了`CLR绑定`
- 确保`没有勾选Development Build`的情况下发布成正式真机运行包，而`不是在Editor中直接运行`

ILRuntime设计上为了在开发时提供更多的调试支持，在Unity Editor中运行会有很多额外的性能开销，
因此在Unity Editor中直接测试并不能代表ILRuntime的实际运行性能。

# 2、安装

ILRuntime1.6版新增了Package Manager发布，使用Unity2018以上版本可以直接通过Package Manager安装

## 节点信息

```
"scopedRegistries": [
  {
    "name": "ILRuntime",
    "url": "https://registry.npmjs.org",
    "scopes": [
      "com.ourpalm"
    ]
  }
],
```

示例导入工程后有可能因为没开启unsafe导致编译报错，可以在PlayerSettings中勾选Allow unsafe code解决编译问题。

## 开始使用

```
ILRuntime.Runtime.Enviorment.AppDomain appdomain;
void Start()
{
    StartCoroutine(LoadILRuntime());
}

IEnumerator LoadILRuntime()
{
    appdomain = new ILRuntime.Runtime.Enviorment.AppDomain();
#if UNITY_ANDROID
    WWW www = new WWW(Application.streamingAssetsPath + "/Hotfix.dll");
#else
    WWW www = new WWW("file:///" + Application.streamingAssetsPath + "/Hotfix.dll");
#endif
    while (!www.isDone)
        yield return null;
    if (!string.IsNullOrEmpty(www.error))
        Debug.LogError(www.error);
    byte[] dll = www.bytes;
    www.Dispose();
#if UNITY_ANDROID
    www = new WWW(Application.streamingAssetsPath + "/Hotfix.pdb");
#else
    www = new WWW("file:///" + Application.streamingAssetsPath + "/Hotfix.pdb");
#endif
    while (!www.isDone)
        yield return null;
    if (!string.IsNullOrEmpty(www.error))
        Debug.LogError(www.error);
    byte[] pdb = www.bytes;
    System.IO.MemoryStream fs = new MemoryStream(dll);
    System.IO.MemoryStream p = new MemoryStream(pdb);
    appdomain.LoadAssembly(fs, p, new Mono.Cecil.Pdb.PdbReaderProvider());    
    
    OnILRuntimeInitialized();
}

void OnILRuntimeInitialized()
{
    appdomain.Invoke("Hotfix.Game", "Initialize", null, null);
}
```

## 调试插件

ILRuntime提供了一个支持Visual Studio 2015、Visual Studio 2017和Visual Studio 2019的调试插件，用来源码级调试你的热更脚本。

# 3、委托使用

如果只在热更新的DLL项目中使用的委托，是不需要任何额外操作的，就跟在通常的C#里那样使用即可

如果你需要将委托实例传给ILRuntime外部使用，那则根据情况，你需要额外添加适配器或者转换器。
需要注意的是，一些编译器功能也会生成将委托传出给外部使用的代码，例如：

> Linq当中where xxxx == xxx，会需要将xxx == xxx这个作为lambda表达式传给Linq.Where这个外部方法使用
> OrderBy()方法，原因同上

如果在运行时发现缺少注册某个指定类型的委托适配器或者转换器时，ILRuntime会抛出相应的异常，根据提示添加注册即可。

## 委托适配器

如果将委托实例传出给ILRuntime外部使用，那就意味着需要将委托实例转换成真正的CLR（C#运行时）委托实例，这个过程需要动态创建CLR的委托实例。由于IL2CPP之类的AOT编译技术无法在运行时生成新的类型，所以在创建委托实例的时候ILRuntime选择了显式注册的方式，以保证问题不被隐藏到上线后才发现。

> 同一个参数组合的委托，只需要注册一次即可，例如：

```
delegate void SomeDelegate(int a, float b);

Action<int, float> act;
```

> 这两个委托都只需要注册一个适配器即可。 注册方法如下

```
appDomain.DelegateManager.RegisterMethodDelegate<int, float>();
```

> 如果是带返回类型的委托，例如：

```
delegate bool SomeFunction(int a, float b);

Func<int, float, bool> act;
```

> 需要按照以下方式注册

```
appDomain.DelegateManager.RegisterFunctionDelegate<int, float, bool>();
```

## 委托转换器

ILRuntime内部是使用Action,以及Func这两个系统自带委托类型来生成的委托实例，所以如果你需要将一个`不是Action或者Func类型`的委托实例传到ILRuntime外部使用的话，除了委托适配器，还需要额外写一个转换器，将Action和Func转换成你真正需要的那个委托类型。

比如上面例子中的SomeFunction类型的委托，其所需的Convertor应如下实现：

```
app.DelegateManager.RegisterDelegateConvertor<SomeFunction>((action) =>
{
    return new SomeFunction((a, b) =>
    {
       return ((Func<int, float, bool>)action)(a, b);
    });
});
```

## 建议

为了避免不必要的麻烦，以及后期热更出现问题，建议项目遵循以下几点：

- 尽量`避免不必要的`跨域委托调用
- 尽量使用`Action以及Func`这两个系统内置万用委托类型

# 4、跨域继承

如果你想在热更DLL项目当中`继承一个Unity主工程里的类`，或者`实现一个主工程里的接口`，你需要在Unity主工程中实现一个继承适配器。
方法如下：

```
public class TestClass2Adapter : CrossBindingAdaptor
    {
	    //定义访问方法的方法信息
        static CrossBindingMethodInfo mVMethod1_0 = new CrossBindingMethodInfo("VMethod1");
        static CrossBindingFunctionInfo<System.Boolean> mVMethod2_1 = new CrossBindingFunctionInfo<System.Boolean>("VMethod2");
        static CrossBindingMethodInfo mAbMethod1_3 = new CrossBindingMethodInfo("AbMethod1");
        static CrossBindingFunctionInfo<System.Int32, System.Single> mAbMethod2_4 = new CrossBindingFunctionInfo<System.Int32, System.Single>("AbMethod2");
        public override Type BaseCLRType
        {
            get
            {
                return typeof(ILRuntimeTest.TestFramework.TestClass2);//这里是你想继承的类型
            }
        }

        public override Type AdaptorType
        {
            get
            {
                return typeof(Adapter);
            }
        }

        public override object CreateCLRInstance(ILRuntime.Runtime.Enviorment.AppDomain appdomain, ILTypeInstance instance)
        {
            return new Adapter(appdomain, instance);
        }

        public class Adapter : ILRuntimeTest.TestFramework.TestClass2, CrossBindingAdaptorType
        {
            ILTypeInstance instance;
            ILRuntime.Runtime.Enviorment.AppDomain appdomain;

            //必须要提供一个无参数的构造函数
            public Adapter()
            {

            }

            public Adapter(ILRuntime.Runtime.Enviorment.AppDomain appdomain, ILTypeInstance instance)
            {
                this.appdomain = appdomain;
                this.instance = instance;
            }

            public ILTypeInstance ILInstance { get { return instance; } }

            //下面将所有虚函数都重载一遍，并中转到热更内
            public override void VMethod1()
            {
                if (mVMethod1_0.CheckShouldInvokeBase(this.instance))
                    base.VMethod1();
                else
                    mVMethod1_0.Invoke(this.instance);
            }

            public override System.Boolean VMethod2()
            {
                if (mVMethod2_1.CheckShouldInvokeBase(this.instance))
                    return base.VMethod2();
                else
                    return mVMethod2_1.Invoke(this.instance);
            }

            protected override void AbMethod1()
            {
                mAbMethod1_3.Invoke(this.instance);
            }

            public override System.Single AbMethod2(System.Int32 arg1)
            {
                return mAbMethod2_4.Invoke(this.instance, arg1);
            }

            public override string ToString()
            {
                IMethod m = appdomain.ObjectType.GetMethod("ToString", 0);
                m = instance.Type.GetVirtualMethod(m);
                if (m == null || m is ILMethod)
                {
                    return instance.ToString();
                }
                else
                    return instance.Type.FullName;
            }
        }
    }
```

因为跨域继承必须要注册适配器。 如果是热更DLL里面继承热更里面的类型，不需要任何注册。

```
appdomain.RegisterCrossBindingAdaptor(new ClassInheritanceAdaptor());
```

# 5、反射

用C#开发项目，很多时候会需要使用反射来实现某些功能。但是在脚本中使用反射其实是一个非常困难的事情。因为这需要把ILRuntime中的类型转换成一个真实的C#运行时类型，并把它们映射起来

默认情况下，System.Reflection命名空间中的方法，并不可能得知ILRuntime中定义的类型，因此无法通过Type.GetType等接口取得热更DLL里面的类型。而且ILRuntime里的类型也并不是一个System.Type。

为了解决这个问题，ILRuntime额外实现了几个用于反射的辅助类：`ILRuntimeType`，`ILRuntimeMethodInfo`，`ILRuntimeFieldInfo`等，来模拟系统的类型来提供部分反射功能

## 通过反射获取Type

在`热更DLL`当中，直接调用Type.GetType(“TypeName”)或者typeof(TypeName)均可以得到有效System.Type类型实例

```
//在热更DLL中，以下两种方式均可以
Type t = typeof(TypeName);
Type t2 = Type.GetType("TypeName");
```



在`Unity主工程中`，无法通过Type.GetType来取得热更DLL内部定义的类，而只能通过以下方式得到System.Type实例：

```
IType type = appdomain.LoadedTypes["TypeName"];
Type t = type.ReflectedType;
```

## 通过反射创建实例

在`热更DLL`当中，可以直接通过Activator来创建实例：

```
Type t = Type.GetType("TypeName");//或者typeof(TypeName)
//以下两种方式均可以
object instance = Activator.CreateInstance(t);
object instance = Activator.CreateInstance<TypeName>();
```

在`Unity主工程中`，无法通过Activator来创建热更DLL内类型的实例，必须通过AppDomain来创建实例：

```
object instance = appdomain.Instantiate("TypeName");
```



## 通过反射调用方法

在`热更DLL`当中，通过反射调用方法跟通常C#用法没有任何区别

```
Type type = typeof(TypeName);
object instance = Activator.CreateInstance(type);
MethodInfo mi = type.GetMethod("foo");
mi.Invoke(instance, null);
```

在`Unity主工程中`，可以通过C#通常用法来调用，也可以通过ILRuntime自己的接口来调用，两个方式是等效的：

```
IType t = appdomain.LoadedTypes["TypeName"];
Type type = t.ReflectedType;

object instance = appdomain.Instantiate("TypeName");

//系统反射接口
MethodInfo mi = type.GetMethod("foo");
mi.Invoke(instance, null);

//ILRuntime的接口
IMethod m = t.GetMethod("foo", 0);
appdomain.Invoke(m, instance, null);
```



## 通过反射获取和设置Field的值

在热更DLL和Unity主工程中获取和设置Field的值跟通常C#用法没有区别

```
Type t;
FieldInfo fi = t.GetField("field");
object val = fi.GetValue(instance);
fi.SetValue(instance, val);
```



## 通过反射获取Attribute标注

在热更DLL和Unity主工程中获取Attribute标注跟通常C#用法没有区别

```
Type t;
FieldInfo fi = t.GetField("field");
object[] attributeArr = fi.GetCustomAttributes(typeof(SomeAttribute), false);
```



## 限制和注意事项

- 在Unity主工程中不能通过new T()的方式来创建热更工程中的类型实例

# 6、CLR重定向

在开发中，如ILRuntime的反射那篇文档中说的，一些依赖反射的接口是没有办法直接运行的，最典型的就是在Unity主工程中通过new T()创建热更DLL内类型的实例。
细心的朋友一定会好奇，为什么Activator.CreateInstance();这个明显内部是new T();的接口可以直接调用呢？

ILRuntime为了解决这类问题，引入了CLR重定向机制。 原理就是当IL解译器发现需要调用某个指定CLR方法时，将实际调用重定向到另外一个方法进行挟持，再在这个方法中对ILRuntime的反射的用法进行处理

刚刚提到的Activator.CreateInstance的CLR重定向定义如下：

```
public static StackObject* CreateInstance(ILIntepreter intp, StackObject* esp, List<object> mStack, CLRMethod method, bool isNewObj)
{
    //获取泛型参数<T>的实际类型
    IType[] genericArguments = method.GenericArguments;
    if (genericArguments != null && genericArguments.Length == 1)
    {
        var t = genericArguments[0];
        if (t is ILType)//如果T是热更DLL里的类型
        {
            //通过ILRuntime的接口来创建实例
            return ILIntepreter.PushObject(esp, mStack, ((ILType)t).Instantiate());
        }
        else
            return ILIntepreter.PushObject(esp, mStack, Activator.CreateInstance(t.TypeForCLR));//通过系统反射接口创建实例
    }
    else
        throw new EntryPointNotFoundException();
}
```



要让这段代码生效，需要执行相对应的注册方法：

```
foreach (var i in typeof(System.Activator).GetMethods())
{
    //找到名字为CreateInstance，并且是泛型方法的方法定义
    if (i.Name == "CreateInstance" && i.IsGenericMethodDefinition)
    {
        appdomain.RegisterCLRMethodRedirection(i, CreateInstance);
    }
}
```



## 带参数的方法的重定向

刚刚的例子当中，由于CreateInstance方法并没有任何参数，所以需要另外一个例子来展示用法，最好的例子就是Unity的Debug.Log接口了，默认情况下，如果在DLL工程中调用该接口，是没有办法显示正确的调用堆栈的，会给开发带来一些麻烦，下面我会展示怎么通过CLR重定向来实现在Debug.Log调用中打印热更DLL中的调用堆栈

```
public unsafe static StackObject* DLog(ILIntepreter __intp, StackObject* __esp, List<object> __mStack, CLRMethod __method, bool isNewObj)
{
    ILRuntime.Runtime.Enviorment.AppDomain __domain = __intp.AppDomain;
    StackObject* ptr_of_this_method;
    //只有一个参数，所以返回指针就是当前栈指针ESP - 1
    StackObject* __ret = ILIntepreter.Minus(__esp, 1);
    //第一个参数为ESP -1， 第二个参数为ESP - 2，以此类推
    ptr_of_this_method = ILIntepreter.Minus(__esp, 1);
    //获取参数message的值
    object message = StackObject.ToObject(ptr_of_this_method, __domain, __mStack);
    //需要清理堆栈
    __intp.Free(ptr_of_this_method);
    //如果参数类型是基础类型，例如int，可以直接通过int param = ptr_of_this_method->Value获取值，
    //关于具体原理和其他基础类型如何获取，请参考ILRuntime实现原理的文档。
			
    //通过ILRuntime的Debug接口获取调用热更DLL的堆栈
    string stackTrace = __domain.DebugService.GetStackTrance(__intp);
    Debug.Log(string.Format("{0}\n{1}", format, stackTrace));

    return __ret;
}
```

然后在通过下面的代码注册重定向即可：

```
appdomain.RegisterCLRMethodRedirection(typeof(Debug).GetMethod("Log"), DLog);
```

# 7、CLR绑定

通常情况下，如果要从热更DLL中调用Unity主工程或者Unity的接口，是需要通过反射接口来调用的，包括市面上不少其他热更方案，也是通过这种方式来对CLR方接口进行调用的。

但是这种方式有着明显的弊端，最突出的一点就是通过反射来调用接口调用效率会比直接调用低很多，再加上反射传递函数参数时需要使用`object[]`数组，这样不可避免的每次调用都会产生不少GC Alloc。众所周知GC Alloc高意味着在Unity中执行会存在较大的性能问题。

ILRuntime通过CLR方法绑定机制，可以`选择性`的对经常使用的CLR接口进行直接调用，从而尽可能的消除反射调用开销以及额外的`GC Alloc`

## 使用方法

CLR绑定借助了ILRuntime的CLR重定向机制来实现，因为实质上也是将对CLR方法的反射调用重定向到我们自己定义的方法里面来。但是手动编写CLR重定向方法是个工作量非常巨大的事，而且要求对ILRuntime底层机制非常了解（比如如何装拆箱基础类型，怎么处理Ref/Out引用等等），因此ILRuntime提供了一个代码生成工具来自动生成CLR绑定代码。

CLR绑定代码的自动生成工具使用方法如下：

```
[MenuItem("ILRuntime/Generate CLR Binding Code by Analysis")]
 static void GenerateCLRBindingByAnalysis()
 {
     //用新的分析热更dll调用引用来生成绑定代码
     ILRuntime.Runtime.Enviorment.AppDomain domain = new ILRuntime.Runtime.Enviorment.AppDomain();
     using (System.IO.FileStream fs = new System.IO.FileStream("Assets/StreamingAssets/HotFix_Project.dll", System.IO.FileMode.Open, System.IO.FileAccess.Read))
     {
         domain.LoadAssembly(fs);

         //Crossbind Adapter is needed to generate the correct binding code
         InitILRuntime(domain);
         ILRuntime.Runtime.CLRBinding.BindingCodeGenerator.GenerateBindingCode(domain, "Assets/ILRuntime/Generated");
     }

     AssetDatabase.Refresh();
 }

 static void InitILRuntime(ILRuntime.Runtime.Enviorment.AppDomain domain)
 {
     //这里需要注册所有热更DLL中用到的跨域继承Adapter，否则无法正确抓取引用
     domain.RegisterCrossBindingAdaptor(new MonoBehaviourAdapter());
     domain.RegisterCrossBindingAdaptor(new CoroutineAdapter());
     domain.RegisterCrossBindingAdaptor(new TestClassBaseAdapter());
     domain.RegisterValueTypeBinder(typeof(Vector3), new Vector3Binder());
 }
```



在CLR绑定代码生成之后，需要将这些绑定代码注册到AppDomain中才能使CLR绑定生效，但是一定要记得将CLR绑定的注册写在CLR重定向的注册后面，因为同一个方法只能被重定向一次，只有先注册的那个才能生效。

注册方法如下：

```
ILRuntime.Runtime.Generated.CLRBindings.Initialize(appdomain);
```

# 8、LitJson集成

Json序列化是开发中非常经常需要用到的功能，考虑到其通用性，因此ILRuntime对LitJson这个序列化库进行了集成

## 初始化

在使用LitJson前，需要对LitJson进行注册，注册方法很简单，只需要在ILRuntime初始化阶段，在注册CLR绑定之前，执行下面这行代码即可：

```
LitJson.JsonMapper.RegisterILRuntimeCLRRedirection(appdomain);
```

## 使用

LitJson的使用非常简单，将一个对象转换成json字符串，只需要下面这行代码即可

```
string json = JsonMapper.ToJson(obj);
```

将json字符串反序列化成对象也同样只需要一行代码

```
JsonTestClass obj = JsonMapper.ToObject<JsonTestClass>(json);
```

其他具体使用方法请参考LitJson库的文档即可

# 9、iOS IL2CPP打包注意事项

鉴于IL2CPP的特殊性，实际在iOS的发布中可能会遇到一些问题，在这里给大家介绍几个iOS发布时可能会遇到的问题。

IL2CPP和mono的最大区别就是不能在运行时动态生成代码和类型，所以这就要求必须在编译时就完全确定需要用到的类型。

## 类型裁剪

IL2CPP在打包时会自动对Unity工程的DLL进行裁剪，将代码中没有引用到的类型裁剪掉，以达到减小发布后ipa包的尺寸的目的。然而在实际使用过程中，很多类型有可能会被意外剪裁掉，造成运行时抛出找不到某个类型的异常。特别是通过反射等方式在编译时无法得知的函数调用，在运行时都很有可能遇到问题。

Unity提供了一个方式来告诉Unity引擎，哪些类型是不能够被剪裁掉的。具体做法就是在Unity工程的Assets目录中建立一个叫link.xml的XML文件，然后按照下面的格式指定你需要保留的类型：

```
<linker>
  <assembly fullname="UnityEngine" preserve="all"/>
  <assembly fullname="Assembly-CSharp">
    <namespace fullname="MyGame.Utils" preserve="all"/>
    <type fullname="MyGame.SomeClass" preserve="all"/>
  </assembly>  
</linker>
```



## 泛型实例

每个泛型实例实际上都是一个独立的类型，`List<A>` 和 `List<B>`是两个完全没有关系的类型，这意味着，如果在运行时无法通过JIT来创建新类型的话，代码中没有直接使用过的泛型实例都会在运行时出现问题。

在ILRuntime中解决这个问题有两种方式，一个是使用CLR绑定，把用到的泛型实例都进行CLR绑定。另外一个方式是在Unity主工程中，建立一个类，然后在里面定义用到的那些泛型实例的public变量。这两种方式都可以告诉IL2CPP保留这个类型的代码供运行中使用。

因此建议大家在实际开发中，尽量使用热更DLL内部的类作为泛型参数，因为DLL内部的类型都是ILTypeInstance，只需处理一个就行了。此外如果泛型模版类就是在DLL里定义的的话，那就完全不需要进行任何处理。

## 泛型方法

跟泛型实例一样，`foo.Bar<TypeA>` 和`foo.Bar<TypeB>`是两个完全不同的方法，需要在主工程中显式调用过，IL2CPP才能够完整保留，因此需要尽量避免在热更DLL中调用Unity主工程的泛型方法。如果在iOS上实际运行遇到报错，可以尝试在Unity的主工程中随便写一个static的方法，然后对这个泛型方法调用一下即可，这个方法无需被调用，只是用来告诉IL2CPP我们需要这个方法

# 10、ILRuntime的性能优化建议

## Release vs Debug

ILRuntime的性能跟编译模式和Unity发布选项有着非常大的关系，要想ILRuntime发挥最高性能，需要确保以下两点：

- 热更用的DLL编译的时候一定要选择Release模式，或者开启代码优化选项，Release模式会比Debug模式的性能高至少2倍
- 关闭Development Build选项来发布Unity项目。在Editor中或者开启Development Build选项发布会开启ILRuntime的Debug框架，以提供调用堆栈行号以及调试服务，这些都会额外耗用不少性能，因此正式发布的时候可以不加载pdb文件，以节省更多内存

## CLR绑定

默认情况下，ILRuntime中调用Unity主工程的方法，ILRuntime会通过反射对目标方法进行调用，这个过程会因为装箱，拆箱等操作，产生大量的GC Alloc和额外开销，因此我们需要借助CLR绑定功能，将我们需要的函数调用进行静态绑定，这样在进行调用的时候就不会出现GC Alloc和额外开销了。

> 在Unity的示例工程中，有关于CLR绑定使用的例子，
> 通过ILRuntime菜单里的Generate CLRBinding code选项可以自动生成所需要的绑定代码

## 值类型

由于值类型的特殊和ILRuntime的实现原理，使用ILRuntime外部定义的值类型（例如UnityEngine.Vector3）在默认情况下会造成额外的装箱拆箱开销，以及相对应的GC Alloc内存分配。

为了解决这个问题，ILRuntime在1.3.0版中增加了值类型绑定（ValueTypeBinding）机制，通过对这些值类型添加绑定器，可以大幅增加值类型的执行效率，以及避免GC Alloc内存分配。具体用法请参考ILRuntime的Unity3D示例工程或者ILRuntime的TestCases测试用例工程。

## 接口调用建议

为了调用方便，ILRuntime的很多接口使用了params可变参数，但是有可能会无意间忽视这个操作带来的GCAlloc，例如下面的操作：

```
appdomain.Invoke("MyGame.Main", "Initialize", null);
appdomain.Invoke("MyGame.Main", "Start", null, 100, 200);
```



这两个操作在调用的时候，会分别生成一个`object[0]`和`object[2]`，从而产生GC Alloc，这一点很容易被忽略。所以如果你需要在Update等性能关键的地方调用热更DLL中的方法，应该按照以下方式缓存这个参数数组：

```
object[] param0 = new object[0];
object[] param2 = new object[2];
IMethod m, m2;

void Start()
{
    m = appdomain.LoadedTypes["MyGame.SomeUI"].GetMethod("Update", 0);
	m2 = appdomain.LoadedTypes["MyGame.SomeUI"].GetMethod("SomethingAfterUpdate", 2);
}

void Update()
{
    appdomain.Invoke(m, null, param0);
	param2[0] = this;
	param2[1] = appdomain;
	appdomain.Invoke(m2, null, param2);
}
```



通过缓存IMethod实例以及参数列表数组，可以做到这个Update操作不会产生任何额外的GC Alloc，并且以最高的性能来执行

如果需要传递的参数或返回值中包含int, float等基础类型，那使用上面的方法依然无法消除GC Alloc，为了更高效率的调用，ILRuntime提供了InvocationContext这种调用方式，需要按照如下方式调用

```
int result = 0;
using(var ctx = appdomain.BeginInvoke(m))
{
    //依次将参数压入栈，如果为成员方法，第一个参数固定为对象实例
    ctx.PushObject(this);
	ctx.PushInteger(123);
	//开始调用
	ctx.Invoke();
	//调用完毕后使用对应的Read方法获取返回值
	result = ctx.ReadInteger();
}
```

# 11、ILRuntime的实现原理

ILRuntime借助Mono.Cecil库来读取DLL的PE信息，以及当中类型的所有信息，最终得到方法的IL汇编码，然后通过内置的IL解译执行虚拟机来执行DLL中的代码。

## IL托管栈和托管对象栈

为了高性能进行运算，尤其是栈上的基础类型运算，如int,float,long之类类型的运算，直接借助C#的Stack类实现IL托管栈肯定是个非常糟糕的做法。因为这意味着每次读取和写入这些基础类型的值，都需要将他们进行装箱和拆箱操作，这个过程会非常耗时并且会产生巨量的GC Alloc，使得整个运行时执行效率非常低下。

因此ILRuntime使用unsafe代码以及非托管内存，实现了自己的IL托管栈。

ILRuntime中的所有对象都是以StackObject类来表示的，他的定义如下：

```
struct StackObject
{
    public ObjectTypes ObjectType;
    public int Value; //高32位
    public int ValueLow; //低32位
}
enum ObjectTypes
{
    Null,//null
    Integer,
    Long,
    Float,
    Double,
    StackObjectReference,//引用指针，Value = 指针地址, 
    StaticFieldReference,//静态变量引用,Value = 类型Hash， ValueLow= Field的Index
    Object,//托管对象，Value = 对象Index
    FieldReference,//类成员变量引用，Value = 对象Index, ValueLow = Field的Index
    ArrayReference,//数组引用，Value = 对象Index, ValueLow = 元素的Index
}
```

通过StackObject这个值类型，我们可以表达C#当中所有的基础类型，因为所有基础类型都可以表达为8位到64位的integer。对于非基础类型而言，我们额外需要一个List来储存他的object引用对象，而Value则可以存储这个对象在List中的Index。由此我们就可以表达C#中所有的类型了。

## 托管调用栈

ILRuntime在进行方法调用时，需要将方法的参数先压入托管栈，然后执行完毕后需要将栈还原，并把方法返回值压入栈。

具体过程如下图所示

```
调用前:                                调用完成后:
|---------------|                     |---------------|
|     参数1     |     |-------------->|   [返回值]    |
|---------------|     |               |---------------|
|      ...      |     |               |     NULL      |
|---------------|     |               |---------------|
|     参数N     |     |               |      ...      |
|---------------|     |
|   局部变量1   |     |
|---------------|     |
|      ...      |     |
|---------------|     |
|   局部变量1   |     |
|---------------|     |
|  方法栈基址   |     |
|---------------|     |
|   [返回值]    |------
|---------------|
```

函数调用进入目标方法体后，栈指针（后面我们简称为ESP）会被指向方法栈基址那个位置，可以通过ESP-X获取到该方法的参数和方法内部申明的局部变量，在方法执行完毕后，如果有返回值，则把返回值写在方法栈基址位置即可（上图因为空间原因写在了基址后面）。

当方法体执行完毕后，ILRuntime会自动平衡托管栈，释放所有方法体占用的栈内存，然后把返回值复制到参数1的位置，这样后续代码直接取栈顶部就可以取到上次方法调用的返回值了。