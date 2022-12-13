

# UniTask

## 异步处理&同步处理

同步处理：简单说就是代码按顺序执行，在方法1里调用方法2时，要等到方法2执行完毕才接着执行方法1的代码。
异步处理：简单说就是在两个方法里的代码同时或者来回执行，在方法1里调用方法2时，不等方法2执行完就接着执行接下来的代码。

## 异步不等于多线程

异步处理不等于多线程，因为即使是单线程，也可以通过切换执行的代码来实现异步。典型的例子就是unity的协程。协程就是只运行在主线程来实现异步处理的。
而C#里真正跟多线程相关的是把ThreadPool封装后的Task类。Task类通常通过async/await 来实现异步，但异步和多线程是两个不同的概念。

async/await 和 Task
这两个关键字是C#5.0引进的，本质是由编译器提供的语法糖，来方便进行异步编程用的。对于unity开发者来说，可以看成一个升级版的协程。

```c#
	//协程版等待一秒
	IEnumerator DelayCoroutine()
    {
        Debug.Log("Start");
        yield return new WaitForSeconds(1f);
        Debug.Log("End");
    }
	//Async版等待一秒
	async void DelayTask()
    {
        Debug.Log("Start");
        await Task.Delay(1000);
        Debug.Log("End");
    }
```

## async/await 与 Coroutine 相比的优点

由于是C#提供的功能，所以在非Mono脚本里也能实现异步。
可以方便的拿到异步的返回值。

```c#
	//异步方法，会在最后返回一个string
	async Task<string> DelayTask()
    {
        Debug.Log("Start");
        await Task.Delay(1000);
        Debug.Log("End");
        return "Completed";
    }
	//由于async可以在任何方法前加，同理适用于unity的生命周期函数。
	async void Start()
    {
        var task = DelayTask();
        Debug.Log("异步执行中..");
        var str = await task;//等待异步结果
        Debug.Log(str);
    }
```

## 避免回调地狱

有的时候我们希望在执行完异步操作时执行一个回调方法，但如果这个回调也有异步操作也要回调，就会造成回调的嵌套，降低代码的可读性。
协程的话可以将各个回调做成一个个小协程，之后在一个主协程里yield return。但是由于协程无法返回值，导致如果想要用上一个协程计算出的值的话，只能将回调作为委托传进去，无法避免回调的嵌套。
但async/await是可以返回值的，可以把回调改写成await的顺序执行。

```c#
 	async void Start()
    {
        var task = DelayTask();
        Debug.Log($"异步执行中..");
        var str = await task;//等待异步结果
        var task2 = AsyncFun2(str);//利用第一个结果执行第二个异步方法
        Debug.Log($"异步执行中..");
        str = await task2();//等待第二个异步结果
        Debug.Log(str);
    }
```

## async/await是可以用Try-Catch捕获异常，协程不行。

task 取消的问题
async/await需要明确地取消正在执行的异步方法，比较麻烦。
由于async/await异步实现是依靠着Task实例。Task实例是有可能是多线程的，由于线程是操作系统层面的资源就导致无法直接停止一个Task。所以我们只能做一个公共变量，task在执行异步时不断检查这个变量是否改变，改变的话说明要停止执行，在Task内部自己停止。
C#提供一个“取消标记”叫做CancellationTokenSource.Token，在创建task的时候传入此参数，就可以将主线程和任务相关联，然后在任务中设置“取消信号“叫做ThrowIfCancellationRequested来等待主线程使用Cancel来通知，一旦cancel被调用。task将会抛出OperationCanceledException来中断此任务的执行，最后将当前task的Status的IsCanceled属性设为true。
注意：一定要处理这个异常，可以通过调用Task.Result成员来获取这个异常。如果一直不查询Task的Exception属性。你的代码就永远注意不到这个异常的发生，如果不能捕捉到这个异常，垃圾回收时，抛出AggregateException，进程就会立即终止，这就是“牵一发动全身”，莫名其妙程序就自己关掉了，谁也不知道这是什么情况。所以，必须调用前面提到的某个成员，确保代码注意到异常，并从异常中恢复。因此可以将调用Task的某个成员来检查Task是否跑出了异常，通常调用Task的Result。
而协程只要把调用这个协程的GameObject删了就会停止协程。或者在开启协程时记下协程实例，要取消时调用StopCoroutine(coroutine)就行。主要原因就是await可以返回值，如果中途取消，就可能导致后面的代码异常，所以只能抛异常。

## UniTask

虽然在Unity(2017版本以上)中可以正常地使用async/await和Task类，但是C#自带地Task类过于繁重而且一些unity里常用的功能要自己实现和封装。于是CySharp公司推出了UniTask来解决这个痛点。
用UniTask有以下优点：

用法和和原先的Task类用法一致。(Task-Like)
比Task更轻量，占用内存少。
对async/await 的优化，实现大幅减少GC。
提供unity相关的功能。
提供各种Awaiter。
实现在editor下await状态的可视化。（利用UniTaskTracker）
但对Unity版本有要求，需要使用Unity2018.3以上版本。
对同一个UniTask实例不能两次await，不然会报错。

## 生成UniTask实例的方法

利用async/await 同C#的用法一样，只不过是将返回值改成相应的UniTask的结构体。
Task ——> UniTask
Task<T> ——> UniTask<T>
void ——> UniTaskVoid //用于不需要返回UniTask的异步方法

利用UniTaskCompletionSource创建
用法如下：

```c#
	async void Start()
    {
        var source = new UniTaskCompletionSource();
        ReadyForCompleted(source).Forget();//只引发不考虑其是否完成
        Debug.Log("Do Something...");
        source.TrySetResult();//设置完成
        //source.TrySetException(Exception);//设置失败
        //source.TrySetCanceled();//设置取消
        Debug.Log("Completed");
    }


	async UniTask ReadyForCompleted(UniTaskCompletionSource source)
    {
        Debug.Log("等待");
        await source.Task;
        Debug.Log("完成");
    }
```

其实就是起一个Task，可以手动的设置是否完成，异常或者取消。
相应的有一个泛型类UniTaskCompletionSource<T>，可以设置返回值。
注意一旦执行了TrySet其中一个，则该实例再执行其他TrySet方法是无效果的。
注意：这个生成的UniTask是可以重复await的。

AutoResetUniTaskCompletionSource.Create()
2.0版本加入的一个UniTaskCompletionSource的池化版本，用法同UniTaskCompletionSource，只是获取实例的方法不同。而且这个只能await一次，因为要被回收走。适合在局部作用域里使用，随用随扔

## UniTask常用的静态方法

```c#
1、UniTask.Run(Action)/ UniTask.Run(Function);//用法同对于的Task.Run方法，就是将委托内容方法放在线程池里运行。运行完毕后返回主线程（configawait设为true时）。

2、UniTask.Delay
UniTask.Delay(1000); //延迟1000ms
UniTask.Delay(TimeSpan.FromSeconds(1));//延迟1s
UniTask.Delay(1000, delayTiming: PlayerLoopTiming.FixedUpdate);//以FixedUpdate的时间来等待

3、UniTask.DelayFrame //返回一个延迟几帧后完成的UniTask
UniTask.DelayFrame(3);//等待3帧（默认 update循环）
UniTask.DelayFrame(3, PlayerLoopTiming.FixedUpdate);//等待3帧（Fixedupdate循环）

4、UniTask.Yield() //等待1帧

5、UniTask.SwitchToThreadPool / UniTask.SwitchToMainThread
//用来切换代码是在主线程跑还是线程池里跑。
await UniTask.Yield();
//之后都在主线程跑
await UniTask.SwitchToThreadPool();
//之后都在线程池跑
await UniTask.SwitchToMainThread();
//之后回到主线程跑

yield和SwitchToMainThread区别在于，如果已经是主线程下的话，SwitchToMainThread不会再等待一帧，而yield无论是不是在主线程，都会等待1帧。

6、UniTask.WaitUntil/UniTask.WaitWhile
类似与协程里用的WaitUntil和WaitWhile，可以指定是哪一个循环里Check。
await UniTask.WaitUntil(()=> isActiveAndEnabled,PlayerLoopTiming.FixedUpdate);

7、UniTask.WaitUntilValueChanged
等到指定对象的参数发生变化时，才完成。
var str = await UniTask.WaitUntilValueChanged(this.transform,x =>x.position);//第一个参数时判断目标，第二个参数是判断方法的委托。如果这个返回值变的话，即为发生变化。
Debug.Log(str);

注意：检测的target是一个弱引用，即可能会被GC回收。如果被GC回收的话，await就会被取消。

8、UniTask.WhenAll(List)
同Task.WhenAll()等待所有Task完成后完成，但UniTask版可以返回不同类型的值。
var num = UniTask.Run(()=>1);
var fl = UniTask.Run(()=>0.5f);
var str = UniTask.Run(()=>"aa");
var (p1, p2, p3) = await UniTask.WhenAll(num, fl, str);

9、UniTask.WhenAny(List)
同Task.WhenAny()等待其中一个Task完成即为完成。
private async UniTask<IPAddress> SelectHostAsync(IPAddress[] apiHost)
{
    var tasks = apiHost.Select(PingAsync).ToArray();//不考虑取消
    var (_, result) = await UniTask.WhenAny(tasks);
    return result;
}
private async UniTask<IPAddress> PingAsync(IPAddress iP)
{
    var ping = new Ping(iP.ToString());
    while (!ping.isDone)
    {
        await UniTask.Yield();
    }
    return iP;
}
```


以下是2.0后加的方法

```c#
10、UniTask.Create<T>(Function(UniTask<T>))
用异步委托快速生成返回UniTask的异步方法。
UniTask.Create(async ()=> 
{
    Debug.Log("aa");
    await UniTask.Delay(1000);
    return "11"; 
});

11、UniTask.Defer(Function(UniTask<T>))
用异步委托快速生成返回UniTask的异步方法，但在创建时不执行，但在await时才执行。
UniTask.Defer(async () => 
{
    Debug.Log("aa");
    await UniTask.Delay(1000);
    return "11";
});

12、UniTask.Lazy(Function(UniTask<T>))
用异步委托生成一个AsyncLazy型对象，在创建时不执行，但在await时才执行。与Defer不同的是这个可以重复await。
var asyncLazy = UniTask.Lazy(async () =>
{  
    Debug.Log("aa");
    await UniTask.Delay(1000);
    return "11";
});
await asyncLazy.Task;

13、UniTask.Void(Function(UniTask<T>))
直接启动一个异步委托，不考虑其等待。
UniTask.Void(async () => 
{     
    Debug.Log("aa");   
    await UniTask.Delay(1000);
});

14、UniTask.Action/UnityAction(Function(UniTask<T>))
就是将异步委托封装成Action或UnityAction。
UniTask.Action(async () => 
{   
    Debug.Log("aa"); 
    await UniTask.Delay(1000);
});

等同于：
()=>{
UniTask.Void(async () => 
{        
    Debug.Log("aa");    
    await UniTask.Delay(1000);
});
};


15、uniTask.Timeout/TimeoutWithoutException()
UniTask的实例可以调用Timeout/TimeoutWithoutException()方法来控制超时。两个方法不同点在于抛不抛异常。
//1秒内无法的话直接抛异常
var str = await DelayTask(token).Timeout(TimeSpan.FromSeconds(1));
//1秒内无法完成的话，await本身完成。
//同时complete = false
var (complete, result) = await DelayTask(token).TimeoutWithoutException(TimeSpan.FromSeconds(1));
```

## Unity对象的扩展——Awaiter

对于一些需要用到等待的Unity对象提供GetAwaiter()功能，从而拿到Awaiter对象就可以进行await了。UniTask已经对各种各样的Unity对象进行了GetAwaiter的扩展。

1、Coroutine的Awaiter
可以直接对协程方法进行await 来调用和等待。

```c#
async void Start()
 {
      await DelayCoroutine();
 }
IEnumerator DelayCoroutine()
{
    Debug.Log("Start");
    yield return new WaitForSeconds(1f);
    Debug.Log("End");
}
```

相应的，UniTask实例也可以转化成Coroutine。

```c#
IEnumerator DelayCoroutine()
{
    Debug.Log("Start");
    yield return UniTask.Delay(1000).ToCoroutine();
    Debug.Log("End");
}
```

2、AsyncOperation的Awaiter
Unity本身自带的一些异步方法，也可以用await了。
例如：

```c#
//AsyncOperation的wait
await SceneManager.LoadSceneAsync("NextScene");
//ResourceRequest的wait
await Resources.LoadAsync<Texture>("Icon").ToUniTask();
//AssetBundle加载的wait
await AssetBundle.LoadFromFileAsync("ABPath");
//UnityWebRequestAsyncOperation的wait
var urw = UnityWebRequest.Get("http://unity.com/");
await urw.SendWebRequest();
```


如果需要检查加载的进度的话，要创建一个Progree实例传进去。

```c#
var progress = Progress.Create<float>(f => Debug.Log($"进度是：{f}"));
var urw = UnityWebRequest.Get("http://unity.com/");
await urw.SendWebRequest().ToUniTask(progress: progress);


```

3、UGUI的一些响应方法也可以await

```c#
	public Button btn;
    public Toggle tog;
    public InputField inputField;
    public Slider slider;

async void Start()
{
	//获取token
    var token = this.GetCancellationTokenOnDestroy();
	//只想等待一次的话
	await btn.OnClickAsync();
	await tog.OnValueChangedAsync();
	await inputField.OnEndEditAsync();
	await slider.OnValueChangedAsync();
	
	//想等待多次的话
    //按键点击
    var btnEventHandler = btn.GetAsyncClickEventHandler(token);
    await btnEventHandler.OnClickAsync();

    //Toggle状态更新
    var togEventHandler = tog.GetAsyncValueChangedEventHandler(token);
    await togEventHandler.OnValueChangedAsync();

    //InputField输入完成
    var inputEventHandler = inputField.GetAsyncEndEditEventHandler(token);
    await inputEventHandler.OnEndEditAsync();

    //slider更新
    var sliderEventHandler = slider.GetAsyncValueChangedEventHandler(token);
    await sliderEventHandler.OnValueChangedAsync();
}
```

4、MonoBehaviour的回调函数也可以await



```c#
    //碰撞相关
        var collisionEnterTrigger = this.GetAsyncCollisionEnterTrigger();
        var collisionExitTrigger = this.GetAsyncCollisionExitTrigger();
        var collisionStayTrigger = this.GetAsyncCollisionStayTrigger();
        var enter = await collisionEnterTrigger.OnCollisionEnterAsync();
        var exit = await collisionExitTrigger.OnCollisionExitAsync();
        var stay = await collisionStayTrigger.OnCollisionStayAsync();
    //动画相关
    var animatorIKTrigger = this.GetAsyncAnimatorIKTrigger();
    var animatorMoveTrigger = this.GetAsyncAnimatorMoveTrigger();
    var layerIndex = await animatorIKTrigger.OnAnimatorIKAsync();
    await animatorMoveTrigger.OnAnimatorMoveAsync();

    //Visible
    var visibleTrigger = this.GetAsyncBecameVisibleTrigger();
    var InvisibleTrigger = this.GetAsyncBecameInvisibleTrigger();
    await visibleTrigger.OnBecameVisibleAsync();
    await InvisibleTrigger.OnBecameInvisibleAsync();
```

5、DoTween也可以等待
从OpenUPM导入DOTween后，添加“UNITASK_DOTWEEN_SUPPORT”宏后可以用。

```c#
await DoMove(...)
await(//同时执行两个Task，直到两个task都完成。
	DoMove(...).ToUniTask();
	DoMove(...).ToUniTask();
)
```



## 取消正在执行的异步的方法

1、CancellationToken
这个实例本身就是C#用来控制Task取消的类。创建方法如下：

```c#
 //生成Token
        var tokenSource = new CancellationTokenSource();
        var token = tokenSource.Token;
        //将Token设成取消
        tokenSource.Cancel();
        //可以判断token是否取消了
        if (token.IsCancellationRequested)
        {
            Debug.Log("Cancel");
        }
        token.ThrowIfCancellationRequested();//如果token是cancel的话，就抛出OperationCanceledException异常。
```


但每次都新生成一个Token很麻烦，有时候就是想在脚本被销毁时，把挂在它身上的异步方法给停下来。

```c#
var token2 = this.GetCancellationTokenOnDestroy();
```

Task被Cancel的话，UniTask就会在一个Cancel状态。且如果是在await的话，await之后的代码都不会执行。尽量不要省略这个token，在能传的异步方法里把这个传进去。
在一些方法里没有办法传token时就要手动在代码里去判断。例如：

```c#
private async UniTask<string> ReadTxtAsync(string path, CancellationToken token)
    {
        return await UniTask.Run(() => 
        {
            //执行前确认
            token.ThrowIfCancellationRequested();
            var str = File.ReadAllText(path);
            //执行后确认
            token.ThrowIfCancellationRequested();
            return str;
        });
    }
```

2、OperationCanceledException异常
在UniTask里抛出这个异常的话，UniTask就会处于Cancal状态。同时UniTask会吃掉这个异常，不会打出errorlog。
Cancel是一个外部操作，所以应该规定只有收到外部要求cancel时才能抛出这个异常。不应该程序内部自己判断来抛。同时如果在UniTask里try-catch时请把这个异常传出去，不要拦截。

```c#
private async UniTask TaskFunc(CancellationToken token)
{
    try
    {
        await UniTask.Delay(1000, cancellationToken : token);
    }
    catch (Exception e) when(!(e is OperationCanceledException))
    {
        Debug.LogError("Error");
    }
}
```


注意：这个异常只能用于Cancel时抛出，不应用于其他用途。
注意：在UniTask里抛出其他别的异常，UniTask就会变为失败

## Editor下对UniTask的监控

Window/UniTask Tracker，可以查看现在运行中的UniTask，确认是否有泄露的UniTask。
