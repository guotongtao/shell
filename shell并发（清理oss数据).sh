#!/bin/bash
#����2 ������ֹ(interrupt)�ź� "ctrl c" ��Ĳ������ر�fd6 
trap "exec 6>&-;exec 6<&-;exit 0" 2
#�����ܵ��ļ�
tmp_fifofile=/tmp/$$.fifo
#���������ܵ��ļ�
mkfifo $tmp_fifofile
#���ļ����(������6)�򿪹ܵ��ļ�
exec 6<> $tmp_fifofile
#ɾ�������ܵ��ļ�
rm -f $tmp_fifofile

#���Ʋ�����
thread=4
for ((i=1;i<=$thread;i++))
do
  #��ܵ��з�����󲢷������У���fd6�з���$thread ��������Ϊ���ƹ�����read��ȡ
  echo >&6
done

ecsbase=/mystore/hls/vod
ossobject="oss://wandoumiao-video/hls/vod/"
ossutilbin=/home/soft/ossutil64
for uid in `ls -F $ecsbase | grep '/$'`
do
    #ͨ���ļ������ȡ�У�����ȡ��ʱ��ֹͣ��һ����������
    read -u 6
    {
        ecspath="${ecsbase}/${uid}"
        osspath="${ossobject}${uid}"
        $ossutilbin mkdir ${osspath}
        find $ecspath -type f -mtime +1 -exec $ossutilbin cp {} $osspath \; >/dev/null
        #һ������ִ�к�Ҫ��ܵ����ڼ���һ�����У����´�ʹ��
        echo >&6
    }&
done
wait
find $ecsbase -type f -mtime +1 |xargs rm -rf
#�رչܵ�д
exec 6>&-
#�رչܵ���
exec 6<&-