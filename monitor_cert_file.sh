#!/bin/bash
# -------------------------------------------------------------------------------
# Filename:    monitor_cert_file.sh
# Revision:    1.0
# Date:        2019/01/16
# Author:      GuoTT
# Email:
# Website:
# Description: Monitoring ssl certificate changes then reload nginx
# -------------------------------------------------------------------------------
reload_nginx="sudo `ps -ef |grep nginx |grep master |awk '{print $(NF-2)}'` -s reload"
#生成MD5验证文件
function CreateMd5File()
{ 
 md5sum -b $1 > $1.md5
}

#检验MD5文件
function CheckMd5File()
{
 #一致是0，不一致是1
 md5sum -c $1 --status
}
#稳健的reload一次nginx
$($reload_nginx)
sleep 1
if [ `ps -ef |grep nginx |grep worker |grep -v grep |wc -l` -lt 1 ];then
  $($reload_nginx)
fi

while true
do
  #取ssl配置文件
  nginx_conf=`ps -ef |grep nginx |grep master |head -1 |awk '{print $NF}'`
  if [ -n $nginx_conf ];then
    awk -F '[ ;]+' '/ssl_.*conf/{print $3}' $nginx_conf |uniq |while read line
    do
      #取ssl证书和ssl秘钥文件
      ssl_cer=`awk '$1=="ssl_certificate"{sub(/;/,"",$2);print $2}' $line`
      ssl_key=`awk '$1=="ssl_certificate_key"{sub(/;/,"",$2);print $2}' $line`
      #判断ssl证书和ssl秘钥文件md5是否存在，不存在创建，和下次运行作比较，所有下次证书更新之前先生成个本次证书的MD5
      if [ ! -e "$ssl_cer".md5 ];then
        CreateMd5File $ssl_cer
      fi
      if [ ! -e "$ssl_key".md5 ];then
        CreateMd5File $ssl_key
      fi
      #检测ssl证书和ssl秘钥有一个更新，就执行命令重新载入nginx
      if  [[ $(CheckMd5File "$ssl_cer".md5;echo $?) -ne 0 || $(CheckMd5File "$ssl_key".md5;echo $?) -ne 0 ]];then
        $($reload_nginx)
        sleep 1
        #判断reload是否成功，不成功再执行一次
        if [ `ps -ef |grep nginx |grep worker |grep -v grep |wc -l` -lt 1 ];then
          $($reload_nginx)
        fi
        CreateMd5File $ssl_cer
        CreateMd5File $ssl_key
      fi
    done
  fi
done