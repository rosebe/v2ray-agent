#!/usr/bin/env bash
export PATH="/usr/bin/:#$PATH"
purple="\033[35m"
skyBlue="\033[36m"
red="\033[31m"
green="\033[32m"
yellow="\e[93m"
magenta="\e[95m"
cyan="\e[96m"
none="\e[0m"

# todo 先完善正常步骤
installNginx(){
    echo -e "${skyBlue}检查Nginx中...${none} "
    existProcessNginx=`ps -ef|grep nginx|grep -v grep`
    existNginx=`command -v nginx`
    if [ -z "$existProcessNginx" ] && [ -z "$existNginx" ]
    then
        echo -e "${skyBlue}安装Nginx中，如遇到是否安装输入y${none}"
        yum install nginx
        rm -rf /etc/nginx/nginx.conf
        wget -P /etc/nginx/  https://raw.githubusercontent.com/mack-a/v2ray-agent/master/config/nginx.conf
        echo -e "${green}步骤二：Nginx安装成功，执行下一步 ${none}"
    else
        # todo
        echo -e "${purple}检查到Nginx存在，是否停止并卸载，输入y确认：${none}"
        read -e unstallStatus
        if [[ $unstallStatus -eq "y" ||  $unstallStatus -eq "Y" ]]
        then
            echo "卸载"
        else
            echo "不卸载，停止脚本"
        fi
    fi
}
installHttps(){
    echo -e "${skyBlue}安装https中,请输入你要生成tls证书的域名${none}"
    read -e domain
    # grep "domain" * -R|awk -F: "{print $1}"|sort|uniq|xargs sed -i "s/domain/$domain/g"
    # cat /etc/nginx/nginx.conf |grep "domain" * -R|awk -F: "{print $1}"|sort|uniq|xargs sed -i "s/domain/$domain/g"
    sed -i "s/domain/$domain/g" `grep domain -rl /etc/nginx/nginx.conf`
    curl https://get.acme.sh | sh
    sudo ~/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
    ~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/nginx/$domain.crt --keypath /etc/nginx/$domain.key --ecc
    sed -i "s/# ssl_certificate/ssl_certificate/g" `grep "# ssl_certificate" -rl /etc/nginx/nginx.conf`
    sed -i "s/listen 443/listen 443 ssl/g" `grep "listen 443" -rl /etc/nginx/nginx.conf`
    echo -e "${green}步骤三：Https安装成功，执行下一步${none}"
}
installV2Ray(){
    echo -e "${skyBlue}检查V2Ray中...${none} "
    existProcessV2Ray=`ps -ef|grep v2ray|grep -v grep`
    existV2Ray=`command -v v2ray`
    if [ -z "$existProcessV2Ray" ] && [ -z "$existV2Ray" ]
    then
        echo -e "${skyBlue}安装V2Ray中... ${none}"
        wget -P /tmp/v2ray https://github.com/v2ray/v2ray-core/releases/download/v4.21.3/v2ray-linux-64.zip
        cd /tmp/v2ray
        unzip /tmp/v2ray/v2ray-linux-64.zip
        mv /tmp/v2ray/v2ray /usr/bin/
        mv /tmp/v2ray/v2ctl /usr/bin/
        mkdir /usr/bin/v2rayConfig
        wget -P /usr/bin/v2rayConfig https://raw.githubusercontent.com/mack-a/v2ray-agent/master/config/config_ws_tls.json
        touch /usr/bin/v2rayConfig/v2ray_access.log
        touch /usr/bin/v2rayConfig/v2ray_error.log
        echo -e "${green} 步骤三：V2Ray安装成功，执行下一步"
    else
        # todo
        echo -e "检查到V2Ray存在，是否停止并卸载，输入y确认："
        read -e unstallStatus
        if [[ $unstallStatus -eq "y" ||  $unstallStatus -eq "Y" ]]
        then
            echo "卸载"
        else
            echo "不卸载，停止脚本"
        fi
    fi
}
checkOS(){
    systemVersion=`cat /etc/redhat-release|grep CentOS|awk '{print $1}'`
    if [ -n "$systemVersion" ] && [ "$systemVersion" == "CentOS" ]
    then
        echo -e "${purple}步骤一：系统为CentOS，执行下一步  ${none} "
    else
        echo -e "${red}目前仅支持Centos${none}"
        echo -e "${red}退出脚本${none}"
        exit
    fi
}
startServer(){
    echo -e "${green}启动服务${none}"
    nginx
    /usr/bin/v2ray -config /usr/bin/v2rayConfig/config_ws_tls.json &
    echo "安装完毕"
    exit
}
installTools(){
    existProcessWget=`ps -ef|grep wget|grep -v grep`
    existWget=`command -v wget`
    yum update
    if [ -z "$existProcessWget" ] && [ -z "$existWget" ]
    then
        echo -e "${skyBlue}安装wget中...${none}"
        yum install wget
    else
        echo
    fi
    existUnzip=`command -v unzip`
    if [ -z "$existUnzip" ]
    then
        echo -e "${skyBlue}安装zip中...${none}"
        yum install unzip
    else
        echo
    fi
    existSocat=`command -v socat`
    if [ -z "$existSocat" ]
    then
        echo -e "${skyBlue}安装socat中...${none}"
        yum install socat
    else
        echo
    fi
}
upinstall(){
    nginx -s stop
    rm -rf ~/.acme.sh
    yum remove nginx
    rm -rf /tmp/v2ray
    rm -rf /usr/bin/v2ray
    rm -rf /usr/bin/v2ctl
    rm -rf /usr/bin/v2rayConfig
    rm -rf /etc/nginx
    ps -ef|grep v2ray|grep -v grep|awk '{print ${2}'|xargs kill -9
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
           installHttps
           automationFun 4
        ;;
        4)
            installV2Ray
            automationFun 5
        ;;
        5)
            startServer
            exit
        ;;
    esac
}
init(){
    echo -e "${purple}目前此脚本在GCP CentOS7上面测试通过${none}"
    echo -e "${purple}此脚本会执行以下内容:${none}"
    echo -e "${skyBlue} 1.检查系统版本是否为CentOS${none}"
    echo -e "${skyBlue} 2.安装工具包${none}"
    echo -e "${skyBlue} 3.检测nginx是否安装并配置${none}"
    echo -e "${skyBlue} 4.检测https是否安装并配置${none}"
    echo -e "${skyBlue} 5.检测V2Ray是否安装并配置${none}"
    echo -e "${skyBlue} 6.启动服务并退出脚本${none}"
    echo -e "${red}是否进入手动模式y，键入回车进入自动模式（暂时只支持自动模式）:${none}"
    read -e automatic
    if [ "${automatic}" = "y" ]
    then
        echo "手动模式"
    else
        if [ $? = 1 ]
        then
            echo -e "${purple}请检查是否将下列文档${none}\n${skyBlue} [https://github.com/mack-a/v2ray-agent#1%E5%87%86%E5%A4%87%E5%B7%A5%E4%BD%9C] 中 [1.准备工作] 已全部完成，并检查正确${none} \n${purple}键入y确定准备完毕 ${none}"
            read -e prepareStatus
            if [ "${prepareStatus}" = "y" ]
            then
                echo "自动模式"
                automationFun 1
            else
                echo "退出脚本"
                exit
            fi
        else
                echo "退出脚本"
                exit
        fi
    fi
}
init
