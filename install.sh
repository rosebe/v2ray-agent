#!/usr/bin/env bash
export PATH="/usr/bin/:#$PATH"

# todo 先完善正常步骤
installNginx(){
    echo -e '\033[36m   检查Nginx中... \033[0m'
    existProcessNginx=`ps -ef|grep nginx|grep -v grep`
    existNginx=`command -v nginx`
    if [ -z "$existProcessNginx" ] && [ -z "$existNginx" ]
    then
        echo '安装Nginx中，如遇到是否安装输入y'
        yum install nginx
        rm -rf /etc/nginx/nginx.conf
        wget -P /etc/nginx/  https://raw.githubusercontent.com/mack-a/v2ray-agent/master/config/nginx.conf
        echo '步骤二：Nginx安装成功，执行下一步'
    else
        # todo
        echo '检查到Nginx存在，是否停止并卸载，输入y确认：'
        read -e unstallStatus
        if [[ $unstallStatus -eq "y" ||  $unstallStatus -eq "Y" ]]
        then
            echo '卸载'
        else
            echo '不卸载，停止脚本'
        fi
    fi
}
installHttps(){
    echo '安装https中,请输入你要生成tls证书的域名'
    read -e domain
    # grep "domain" * -R|awk -F: '{print $1}'|sort|uniq|xargs sed -i 's/domain/$domain/g'
    # cat /etc/nginx/nginx.conf |grep "domain" * -R|awk -F: '{print $1}'|sort|uniq|xargs sed -i 's/domain/$domain/g'
    sed -i "s/domain/$domain/g" `grep domain -rl /etc/nginx/nginx.conf`
    curl https://get.acme.sh | sh
    #sudo ~/.acme.sh/acme.sh --issue -d test.q2m8.xyz --standalone -k ec-256|grep 'Verify error'
    sudo ~/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
    ~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/nginx/$domain.crt --keypath /etc/nginx/$domain.key --ecc

}
installV2Ray(){
    echo -e '\033[36m   检查V2Ray中... \033[0m'
    existProcessV2Ray=`ps -ef|grep v2ray|grep -v grep`
    existV2Ray=`command -v v2ray`
    if [ -z "$existProcessV2Ray" ] && [ -z "$existV2Ray" ]
    then
        echo '安装V2Ray中...'
        wget -P /tmp/v2ray https://github.com/v2ray/v2ray-core/releases/download/v4.21.3/v2ray-linux-64.zip
        cd /tmp/v2ray
        unzip /tmp/v2ray/v2ray-linux-64.zip
        mv /tmp/v2ray/v2ray /usr/bin/
        mv /tmp/v2ray/v2ctl /usr/bin/
        echo '步骤二：V2Ray安装成功，执行下一步'
    else
        # todo
        echo '检查到V2Ray存在，是否停止并卸载，输入y确认：'
        read -e unstallStatus
        if [[ $unstallStatus -eq "y" ||  $unstallStatus -eq "Y" ]]
        then
            echo '卸载'
        else
            echo '不卸载，停止脚本'
        fi
    fi
}
checkOS(){
    systemVersion=`cat /etc/redhat-release|grep CentOS|awk '{print $1}'`
    if [ -n "$systemVersion" ] && [ "$systemVersion" == "CentOS" ]
    then
        echo -e '\033[35m步骤一：系统为CentOS，执行下一步 \033[0m'
    else
        echo '目前仅支持Centos'
    fi
}
installTools(){
    existProcessWget=`ps -ef|grep wget|grep -v grep`
    existWget=`command -v wget`
    yum update
    if [ -z "$existProcessWget" ] && [ -z "$existWget" ]
    then
        echo '安装wget中...'
        yum install wget
    else
        echo
    fi
    existUnzip=`command -v unzip`
    if [ -z "$existUnzip" ]
    then
        echo '安装zip中...'
        yum install unzip
    else
        echo
    fi
    existSocat=`command -v socat`
    if [ -z "$existSocat" ]
    then
        echo '安装zip中...'
        yum install socat
    else
        echo
    fi
}
manageFun(){
    case $1 in
        checkOS)
            checkOS
        ;;
        installNginx)
            installNginx
        ;;
        installV2Ray)
            installV2Ray
        ;;
        installHttps)
            installHttps
        ;;
    esac
}
automationFun(){
    case $1 in
        1)
            checkOS
            installTools
            automationFun 2
        ;;
        2)
            installNginx
            automationFun 3
        ;;
        3)
            installV2Ray
            automationFun 4
        ;;
        4)
            installHttps
            echo '安装完毕'
            exit
        ;;
    esac
}
init(){
    echo -e "\033[35m此脚本会执行以下内容: \033[0m"
    echo -e "\033[36m  1.检查系统版本是否为CentOS \033[0m"
    echo -e "\033[36m  2.检测nginx是否安装并配置 \033[0m"
    echo -e "\033[36m  3.检测https是否安装并配置 \033[0m"
    echo -e "\033[36m  4.检测V2Ray是否安装并配置 \033[0m"
    echo -e "\033[35m是否进入手动模式y，键入回车进入自动模式: \033[0m"
    read -e automatic
    if [ "$automatic" = "y" ]
    then
        echo '手动模式'
    else
        automationFun 1

        if [ $? = 1 ]
        then
            manageFun installNginx
        else
            echo '退出脚本'
            exit
        fi
    fi
}
upinstall(){
    yum remove nginx
    rm -rf /tmp/v2ray
    rm -rf /usr/bin/v2ray
    rm -rf /usr/bin/v2ctl
    rm -rf /etc/nginx
}
init
