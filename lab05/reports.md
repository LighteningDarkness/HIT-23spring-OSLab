# <center>实验5：进程运行轨迹的跟踪与统计<center/>

## 1.结合自己的体会，谈谈从程序设计者的角度看，单进程编程和多进程编程最大的区别是什么？

单进程编程思维比较线性，按照拓扑顺序一个个来就OK，无需考虑太多他们之间协作以提高性能的事情；多进程除了考虑一切单进程要考虑的事外，还得考虑最大化利用CPU并行计算的同时设计一个相对合理且公平的算法协调每个进程的占用时间以及先后顺序，同时也要避免死锁等异常情况的发生。

两者间的最大区别莫过于指令级别的执行顺序以及性能、编写难度差别：前者性能没后者高，但难度低。

## 2.你是如何修改时间片的？仅针对样本程序建立的进程，在修改时间片前后， `log` 文件的统计结果（不包括Graphic）都是什么样？结合你的修改分析一下为什么会这样变化，或者为什么没变化？

### 修改时间片

fork.c的copy_process()函数中是这样初始化的：

```
*p = *current;             //用来复制父进程的PCB数据信息，包括priority和counter
p->counter = p->priority;  //初始化counter
```

因此只需要找到priorty的位置即可，该位置在宏 `INIT_TASK` 中定义：

```
#define INIT_TASK \
  { 0,15,15, //分别对应state;counter;和priority;
```

将后两个修改为一致的数值即可。

### 结果

时间片为5：

![image-20230615203952848](.\images\img1.png)

时间片15（原始）：

![image-20230615203930731](.\images\img2.png)

时间片25：

![image-20230615203906373](.\images\img3.png)

可以看出，在5，15，25三种时间片下，整体等待时间15<5<25。首先15<5，可能原因为虽然时间片减少可能会减少等待时间，但这里过多的调度花费了更多的时间，因此整体上看等待时间反而变大了；其次5<25，这个在情理之中，因为时间片更长意味着每个进程一旦得到运行，就可以运行不少的时间，进度快，进程切换少，但也更加接近线性，等待时间比较长。

## 3.一些过程记录

### 3.1 process.c

填充的main函数为：

```
int main(int argc, char * argv[])
{
	pid_t children[2]; 
    	int i;
	for(i = 0; i < 2 ; i++)
	{
	    if((children[i] = fork()) == 0) 
		{
			//different cpu and io time
			cpuio_bound(2, i, 2-i);
		} 
		else if (children[i] < 0)
		{
			printf("creation failure: %d\n", i+1);
			return -1;
		}
	}
	for(i = 0; i < 2; i++)
	{
		printf("child's pid: %d\n", children[i]);
	}
	wait(&i);
	return 0;
}
```

图示如下：

![image-20230615204638810](.\images\img4.png)

事实上最后结果也是如此：

![image-20230615204745376](.\images\img5.png)

### 3.2 日志创建&输出信息&输出5种状态

实验指导书给出的fprintk函数利用的是task1的句柄，因此创建文件的工作在task1中进行，task1是task0的子进程，并且由init函数初始化，我们就在这个函数中打开文件：

![image-20230615205002651](.\images\img6.png)

此外，由于脚本文件要求进程1以N开头，然而文件打开在fork后，因此**编写了fprintf函数，用于在用户态下向文件输出**：

```
static int fprintf(const int fd,const char *fmt, ...)
{
	va_list args;
	int i;

	va_start(args, fmt);
	write(fd,printbuf,i=vsprintf(printbuf, fmt, args));
	va_end(args);
	return i;
}
```

用来模拟文件打开前的情况，具体log文件见附件，时间片15示例（图中五种状态都在）为：

![image-20230615205204973](.\images\img7.png)

### 3.3 调度算法修改

时间片修改之前提过不再赘述，schedule函数中需要一些判断：

```
	if (current->pid!=task[next]->pid)
	{
		if (current->state==TASK_RUNNING)
		{
			fprintk(3,"%ld\t%c\t%ld\n",current->pid,'J',jiffies);
		}
		fprintk(3,"%ld\t%c\t%ld\n",task[next]->pid,'R',jiffies);
	}
```

由于switch函数在前后pid相同时不干事，因此需要加上next是否是当前进程的判断；其次由于是切换，原有进程若为TASK_RUNNING只可能为运行态，因此发生了状态转换需要输出，而next直接进入运行态。

### 3.4 一个问题

起初，检查了千遍都没写错但结果就是不正确，后来换了配置文件后就OK了，猜测是bochs版本问题。

2023.6.23更新：从老师描述来看确实是版本问题；在做实验过程中所猜测过的缓冲区问题看来也是存在的，但没改成功有点可惜。