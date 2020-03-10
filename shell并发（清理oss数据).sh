#!/bin/bash
#接受2 程序终止(interrupt)信号 "ctrl c" 后的操作。关闭fd6 
trap "exec 6>&-;exec 6<&-;exit 0" 2
#命名管道文件
tmp_fifofile=/tmp/$$.fifo
#创建命名管道文件
mkfifo $tmp_fifofile
#用文件句柄(随便给个6)打开管道文件
exec 6<> $tmp_fifofile
#删除命名管道文件
rm -f $tmp_fifofile

#控制并发数
thread=4
for ((i=1;i<=$thread;i++))
do
  #向管道中放入最大并发数个行，在fd6中放入$thread 个空行作为令牌供下面read读取
  echo >&6
done

ecsbase=/mystore/hls/vod
ossobject="oss://wandoumiao-video/hls/vod/"
ossutilbin=/home/soft/ossutil64
for uid in `ls -F $ecsbase | grep '/$'`
do
    #通过文件句柄读取行，当行取尽时，停止下一步（并发）
    read -u 6
    {
        ecspath="${ecsbase}/${uid}"
        osspath="${ossobject}${uid}"
        $ossutilbin mkdir ${osspath}
        find $ecspath -type f -mtime +1 -exec $ossutilbin cp {} $osspath \; >/dev/null
        #一个并发执行后要想管道中在加入一个空行，供下次使用
        echo >&6
    }&
done
wait
find $ecsbase -type f -mtime +1 |xargs rm -rf
#关闭管道写
exec 6>&-
#关闭管道读
exec 6<&-