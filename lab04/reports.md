# <center>实验4：系统调用<center/>

## 1.从 `Linux 0.11` 现在的机制看，它的系统调用最多能传递几个参数？

最多三个，分别通过ebx，ecx，edx通用寄存器来实现参数传递。

## 2.你能想出办法来扩大这个限制吗？

1. 增加通用寄存器数量，当然这个方法成本有点高且不可持续发展；
2. 类似如今的Linux，除了使用一定数量的通用寄存器外，当参数数量超出通用寄存器数量时则将超出的这一部分参数压到栈中，通过访问栈来实现参数传递。

## 3.用文字简要描述向 `Linux 0.11` 添加一个系统调用 `foo()` 的步骤。

以下步骤不分顺序，全部完成即可，假设函数原型为 rtype foo()，参数省略因为不重要，图片均为iam与whoami函数示例（**相当于实验过程记录**）。

- 在kernel文件夹下创建foo.c，并实现sys_foo函数
- 在include/linux/sys.h中添加函数声明extern rtype sys_foo()，并在末尾的sys_call_table末端加入sys_foo：![image-20230527145812694](.\images\img1.png)
- 修改include/unistd.h，在图示位置加入宏定义__NR_foo，并且宏定义值要和sys_foo在表中位置相同![image-20230527150036685](.\images\img2.png)
- 修改kernel/system_call.s中的nr_system_calls，使其增加1![image-20230527150300851](.\images\img3.png)
- 修改kernel/Makefile，在OBJS中加入foo.o，并添加编译为foo.o以及foo.s的依赖![image-20230527150216118](.\images\img4.png)![image-20230527150133176](.\images\img5.png)

## 3.实验结果

相关代码在files中

<img src=".\images\img6.png" alt="image-20230527150612360" style="zoom:67%;" />