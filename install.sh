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
        echo -e "${purple}===============================${none}"
        echo -e "${purple}检测到已安装Nginx，是否卸载${none}"
        echo -e "${red}    1.卸载并重新安装【会把默认的安装目录的内容删除】${none}"
        echo -e "${red}    2.跳过并使用已经安装的Nginx以及配置文件【请确认是否是此脚本的配置文件】${none}"
        echo -e "${purple}===============================${none}"
        echo -e "${skyBlue}请选择【数字编号】:${none}"
        read -e nginxStatus
        if [ "${nginxStatus}" = 1 ]
        then
            if [ -n "$existProcessNginx" ]
            then
                echo -e "${purple}Nginx已启动，关闭中...${none}"
                nginx -s stop
            fi
            echo -e "${skyBlue}卸载Nginx中... ${none}"
            yum remove nginx
            echo -e "${skyBlue}卸载Nginx完毕，重装中... ${none}"
            installNginx;
        else
            echo "不卸载，返回主目录"
            echo
            manageFun
        fi
    fi
}
installHttps(){
    echo -e "${skyBlue}安装https中,请输入你要生成tls证书的域名${none}"
    read -e domain
    # grep "domain" * -R|awk -F: "{print $1}"|sort|uniq|xargs sed -i "s/domain/$domain/g"
    # cat /etc/nginx/nginx.conf |grep "domain" * -R|awk -F: "{print $1}"|sort|uniq|xargs sed -i "s/domain/$domain/g"
    existProcessNginx=`ps -ef|grep nginx|grep -v grep`
    if [ ! -z "${existProcessNginx}" ]
    then
        echo '检测到Nginx正在运行，关闭中...'
        nginx -s stop
    fi

    if [ -f "/etc/nginx/nginx.conf" ]
    then
        noExistNginxConfigDomain=`cat /etc/nginx/nginx.conf|grep $domain|grep -v grep`
        if [ ! -z "${noExistNginxConfigDomain}" ]
        then
            sed -i "s/$domain/domain/g" `grep $domain -rl /etc/nginx/nginx.conf`
        fi
        sed -i "s/domain/$domain/g" `grep domain -rl /etc/nginx/nginx.conf`
    fi

    uninstallAcmeStatus="false"
    if [ ! -d "/root/.acme.sh" ]
    then
        echo -e "${skyBlue}安装acme.sh中...${none}"
        curl https://get.acme.sh | sh
        sudo ~/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
    else
        echo -e "${purple}===============================${none}"
        echo -e "${purple}检测到已安装acme.sh，是否卸载${none}"
        echo -e "${red}    1.卸载并重新安装【以前生成的TLS证书会被删除，需要重新输入域名】${none}"
        echo -e "${red}    2.跳过并使用已经安装的acme.sh${none}"
        echo -e "${purple}===============================${none}"
        echo -e "${skyBlue}请选择【数字编号】:${none}"
        read -e acmeStatus
        if [ "${acmeStatus}" = 1 ]
        then
            rm -rf ~/.acme.sh
            uninstallAcmeStatus="true"
        else
            echo -e "${skyBlue}生成证书中...${none}"
        fi
    fi

    if [ "${uninstallAcmeStatus}" = "true" ]
    then
        installHttps
    else
        ~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/nginx/$domain.crt --keypath /etc/nginx/$domain.key --ecc
        sed -i "s/# ssl_certificate/ssl_certificate/g" `grep "# ssl_certificate" -rl /etc/nginx/nginx.conf`
        sed -i "s/listen 443/listen 443 ssl/g" `grep "listen 443" -rl /etc/nginx/nginx.conf`
        echo -e "${green}步骤三：HTTPS执行完毕，请手动确认上方是否有错误，执行下一步${none}"
    fi
}
installV2Ray(){
    echo -e "${skyBlue}检查V2Ray中...${none} "
    existProcessV2Ray=`ps -ef|grep v2ray|grep -v grep`
    existV2Ray=`command -v v2ray`
    if [ -z "$existProcessV2Ray" ] && [ -z "$existV2Ray" ] && [ ! -x "/usr/bin/v2ray" ]
    then
        echo -e "${skyBlue}安装V2Ray中... ${none}"
        wget -P /tmp/V2Ray https://github.com/V2Ray/V2Ray-core/releases/download/v4.21.3/V2Ray-linux-64.zip
        cd /tmp/V2Ray
        unzip /tmp/V2Ray/V2Ray-linux-64.zip
        mv /tmp/V2Ray/v2ray /usr/bin/
        mv /tmp/V2Ray/v2ctl /usr/bin/
        mkdir /usr/bin/V2RayConfig
        wget -P /usr/bin/V2RayConfig https://raw.githubusercontent.com/mack-a/V2Ray-agent/master/config/config_ws_tls.json
        touch /usr/bin/V2RayConfig/V2Ray_access.log
        touch /usr/bin/V2RayConfig/V2Ray_error.log
        echo -e "${green} 步骤三：V2Ray安装成功，执行下一步"
    else
        echo -e "${purple}===============================${none}"
        echo -e "${purple}检测到已安装V2Ray，是否卸载${none}"
        echo -e "${red}    1.卸载并重新安装【配置文件会重新生成】${none}"
        echo -e "${red}    2.跳过并使用已经安装的V2Ray【请确认Nginx的配置与V2Ray配置相同【端口号、Path】】${none}"
        echo -e "${purple}===============================${none}"
        echo -e "${skyBlue}请选择【数字编号】:${none}"
        read -e acmeStatus
        if [ "${acmeStatus}" = 1 ]
        then
            rm -rf /tmp/V2Ray
            rm -rf /usr/bin/v2ray
            rm -rf /usr/bin/v2ctl
            rm -rf /usr/bin/V2RayConfig
            if [ -z `ps -ef|grep v2ray|grep -v grep|awk '{print $2}'` ]
            then
                ps -ef|grep v2ray|grep -v grep|awk '{print $2}'|xargs kill -9
            fi
            installV2Ray
        else
            echo -e "${green} 忽略V2Ray并继续执行"
        fi
    fi
}
checkOS(){
    systemVersion=`cat /etc/redhat-release|grep CentOS|awk '{print $1}'`
    if [ -n "$systemVersion" ] && [ "$systemVersion" == "CentOS" ]
    then
        echo -e "${green}步骤一：系统为CentOS脚本可执行  ${none} "
    else
        echo -e "${red}目前仅支持Centos${none}"
        echo -e "${red}退出脚本${none}"
        exit
    fi
}
# 生成vmess链接
generatorVmess(){
    echo -e "${purple}===============================${none}"
    echo -e "${purple}选择要生成vmess的V2Ray配置文件${none}"
    echo -e "${green}  1.默认【/usr/bin/V2RayConfig/config_ws_tls.json】${none}"
    echo -e "${green}  2.官方默认【/etc/v2ray/config.json】${none}"
    echo -e "${green}  3.手动输入${none}"
    echo -e "${purple}===============================${none}"
    echo -e "${skyBlue}请选择【数字编号】:${none}"
    read -e V2RayPathSelect
    V2RayPath="";

    if [ "$V2RayPathSelect" == "3" ]
    then
        echo -e "${skyBlue}请输入配置文件路径：${none}"
        read -e V2RayPath
    fi
    case $V2RayPathSelect in
        1)
            V2RayPath="/usr/bin/V2RayConfig/config_ws_tls.json"
        ;;
        2)
            V2RayPath="/etc/v2ray/config.json"
        ;;
    esac

    if [ -z "${V2RayPath}" ]
    then
        echo -e ${red}"V2Ray配置文件读取失败，请检查路径"${none}
        init
    else
        # 读取nginx配置文件
        echo -e "${purple}===============================${none}"
        echo -e "${purple}选择要生成vmess的Nginx配置文件路径${none}"
        echo -e "${green}  1.CDN【默认读取/etc/nginx/nginx.conf】${none}"
        echo -e "${green}  2.手动输入Nginx配置文件路径${none}"
        echo -e "${green}  3.非CDN${none}"
        echo -e "${purple}===============================${none}"
        echo -e "${skyBlue}请选择【数字编号】:${none}"
        read -e NginxPathSelect

        if [ "$NginxPathSelect" == "2" ]
        then
            echo -e "${skyBlue}请输入Nginx配置文件路径：${none}"
            read -e NginxPath
        fi

        case $NginxPathSelect in
            1)
                NginxPath="/etc/nginx/nginx.conf"
            ;;
        esac
        if [ -z "${NginxPath}" ]
        then
            echo -e ${red}"Nginx配置文件读取失败，请检查路径"${none}
            init
        fi
        # 执行node生成vmess链接
        echo ${V2RayPath},${NginxPath}
        vmessResult=`curl -L -s https://raw.githubusercontent.com/mack-a/v2ray-agent/master/generator_client_links.js | /root/.nvm/versions/node/v12.8.1/bin/node - ${V2RayPath} ${NginxPath}`
        echo -e "${skyBlue}${vmessResult}${none}"
    fi
}
startServer(){
    echo -e "${green}启动服务${none}"
    nginx
    /usr/bin/v2ray -config /usr/bin/V2RayConfig/config_ws_tls.json &
    echo "启动完毕"
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
    fi
    existSocat=`command -v socat`
    if [ -z "$existSocat" ]
    then
        echo -e "${skyBlue}安装socat中...${none}"
        yum install socat
    fi
    existJq=`command -v jq`
    if [ -z "$existJq" ]
    then
        echo -e ${skyBlue}安装jq中...${none}
        yum install jq
    fi
    existNode=`command -v node`
    if [ -z "$existNode" ]
    then
        echo -e ${skyBlue}安装Nodejs中...${none}
        yum install nodejs
    fi
    existQrencode=`command -v qrencode`
    if [ -z "$existQrencode" ]
    then
        echo -e ${skyBlue}安装qrencode中...${none}
        yum install qrencode
    fi
}
unInstall(){
    nginx -s stop
    rm -rf ~/.acme.sh
    yum remove nginx
    rm -rf /tmp/V2Ray
    rm -rf /usr/bin/v2ray
    rm -rf /usr/bin/v2ctl
    rm -rf /usr/bin/V2RayConfig
    rm -rf /etc/nginx
    ps -ef|grep v2ray|grep -v grep|awk '{print $2}'|xargs kill -9
}
configPath(){
    echo -e "${purple}===============================${none}"
    echo -e "${red}路径如下${none}"
    echo -e "${green} 1.v2ray${none}"
    echo -e "${skyBlue}   1./usr/bin/v2ray 【V2Ray 程序】${none}"
    echo -e "${skyBlue}   2./usr/bin/v2ctl 【V2Ray 工具】${none}"
    echo -e "${skyBlue}   3./usr/bin/V2RayConfig 【V2Ray配置文件，配置文件、log文件】${none}"
    echo -e "${green} 2.Nginx${none}"
    echo -e "${skyBlue}   1./usr/sbin/nginx 【Nginx 程序】${none}"
    echo -e "${skyBlue}   2./etc/nginx/nginx.conf 【Nginx 配置文件】${none}"
    echo -e "${purple}===============================${none}"
    echo
}
manageFun(){
    echo -e "${purple}===============================${none}"
    echo -e "${purple}手动模式功能点目录:${none}"
    echo -e "${skyBlue}  1.检查系统版本是否为CentOS${none}"
    echo -e "${skyBlue}  2.安装工具包${none}"
    echo -e "${skyBlue}  3.检测nginx是否安装并配置${none}"
    echo -e "${skyBlue}  4.检测https是否安装并配置${none}"
    echo -e "${skyBlue}  5.检测V2Ray是否安装并配置${none}"
    echo -e "${skyBlue}  6.启动服务并退出脚本${none}"
    echo -e "${skyBlue}  7.卸载安装的所有内容${none}"
    echo -e "${skyBlue}  8.查看配置文件路径${none}"
    echo -e "${skyBlue}  9.生成Vmess链接${none}"
    echo -e "${skyBlue}  10.返回主目录${none}"
    echo -e "${red}  11.退出脚本${none}"
    echo -e "${purple}===============================${none}"
    echo -e "${skyBlue}请输入要执行的功能【数字编号】:${none}"
    read -e funType
    echo
    case $funType in
        1)
            checkOS
        ;;
        2)
            installTools
        ;;
        3)
            installNginx
        ;;
        4)
            echo -e "${red}此步骤依赖【3.检测nginx是否安装并配置】${none}"
            installHttps
        ;;
        5)
            installV2Ray
        ;;
        6)
            startServer
        ;;
        7)
            unInstall
        ;;
        8)
           configPath
        ;;
        9)
           generatorVmess
        ;;
        10)
           init
        ;;
        11)
           exit
        ;;
    esac
    manageFun
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
            automationFun 6
        ;;
        6)
            generatorVmess
            exit
        ;;
    esac
}

init(){
    echo -e "${purple}目前此脚本在GCP CentOS7上面测试通过${none}"
    echo -e "${purple}===============================${none}"
    echo -e "${purple}支持两种模式：${none}"
    echo -e "${red}    1.自动模式${none}"
    echo -e "${red}    2.手动模式${none}"
    echo -e "${purple}===============================${none}"
    echo -e "${skyBlue}请选择【数字编号】:${none}"
    read -e automatic
    if [ "${automatic}" = 1 ]
    then
        echo -e "${purple}===============================${none}"
        echo -e "${purple}自动模式会执行以下内容:${none}"
        echo -e "${skyBlue}  1.检查系统版本是否为CentOS${none}"
        echo -e "${skyBlue}  2.安装工具包${none}"
        echo -e "${skyBlue}  3.检测nginx是否安装并配置${none}"
        echo -e "${skyBlue}  4.检测https是否安装并配置${none}"
        echo -e "${skyBlue}  5.检测V2Ray是否安装并配置${none}"
        echo -e "${skyBlue}  6.启动服务并退出脚本${none}"
        echo -e "${skyBlue}  7.生成vmess链接${none}"
        echo -e "${purple}===============================${none}"
        automationFun 1
    elif [ "${automatic}" = 2 ]
    then
        manageFun
    fi
}
init
# generatorVmess
