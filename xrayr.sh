# !/bin/bash
# 
# automatically configure xrayr by docker-compose
# Only test on Ubuntu 20.04 LTS Ubuntu 22.04 LTS

XRAYR_PATH="/opt/xrayr"

DC_URL="https://raw.githubusercontent.com/tech-fever/xrayr-docker-script/main/docker-compose.yml"
CONFIG_URL="https://raw.githubusercontent.com/tech-fever/xrayr-docker-script/main/config.yml"

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
export PATH=$PATH:/usr/local/bin

os_arch=""

Get_Docker_URL="https://get.docker.com"
GITHUB_URL="github.com"

# 请填写你的v2board域名，例如：https://v2board.com/
V2BOARD_URL="https://v2board.com/"
# 请填写前端的api key，例如：123456789
V2BOARD_API_KEY="your_api_key"

pre_check() {
    # check root
    [[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1

    ## os_arch
    if [[ $(uname -m | grep 'x86_64') != "" ]]; then
        os_arch="amd64"
    elif [[ $(uname -m | grep 'i386\|i686') != "" ]]; then
        os_arch="386"
    elif [[ $(uname -m | grep 'aarch64\|armv8b\|armv8l') != "" ]]; then
        os_arch="arm64"
    elif [[ $(uname -m | grep 'arm') != "" ]]; then
        os_arch="arm"
    elif [[ $(uname -m | grep 's390x') != "" ]]; then
        os_arch="s390x"
    elif [[ $(uname -m | grep 'riscv64') != "" ]]; then
        os_arch="riscv64"
    fi
}

install_base() {
    (command -v curl >/dev/null 2>&1 && command -v wget >/dev/null 2>&1 && command -v getenforce >/dev/null 2>&1) ||
        (install_soft curl wget)
}

install_soft() {
    # Arch官方库不包含selinux等组件
    (command -v yum >/dev/null 2>&1 && yum makecache && yum install $* selinux-policy -y) ||
        (command -v apt >/dev/null 2>&1 && apt update && apt install $* selinux-utils -y) ||
        (command -v pacman >/dev/null 2>&1 && pacman -Syu $*) ||
        (command -v apt-get >/dev/null 2>&1 && apt-get update && apt-get install $* selinux-utils -y)
}

install() {
    install_base

    echo -e "> 安装xrayr"

    # check directory
    if [ ! -d "$XRAYR_PATH" ]; then
        mkdir -p $XRAYR_PATH
    else
        echo "您可能已经安装过xrayr，重复安装会覆盖数据，请注意备份。"
        read -e -r -p "是否退出安装? [Y/n] " input
        case $input in
        [yY][eE][sS] | [yY])
            echo "退出安装"
            exit 0
            ;;
        [nN][oO] | [nN])
            echo "继续安装"
            ;;
        *)
            echo "退出安装"
            exit 0
            ;;
        esac
    fi
    chmod 777 -R $XRAYR_PATH

    # check docker
    command -v docker >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        echo -e "正在安装 Docker"
        bash <(curl -sL ${Get_Docker_URL}) >/dev/null 2>&1
        if [[ $? != 0 ]]; then
            echo -e "${red}下载脚本失败，请检查本机能否连接 ${Get_Docker_URL}${plain}"
            return 0
        fi
        systemctl enable docker.service
        systemctl start docker.service
        echo -e "${green}Docker${plain} 安装成功"
    fi

    # check docker compose
    command -v docker-compose >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        echo -e "正在安装 Docker Compose"
        wget -t 2 -T 10 -O /usr/local/bin/docker-compose "https://${GITHUB_URL}/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" >/dev/null 2>&1
        if [[ $? != 0 ]]; then
            echo -e "${red}下载脚本失败，请检查本机能否连接 ${GITHUB_URL}${plain}"
            return 0
        fi
        chmod +x /usr/local/bin/docker-compose
        echo -e "${green}Docker Compose${plain} 安装成功"
    fi

    modify_xrayr_config 0

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

modify_xrayr_config() {
    echo -e "> 修改xrayr配置"

    # download docker-compose.yml
    wget -t 2 -T 10 -O /tmp/docker-compose.yml ${DC_URL} >/dev/null 2>&1
    
    if [[ $? != 0 ]]; then
        echo -e "${red}下载docker-compose.yml失败，请检查本机能否连接 ${DC_URL}${plain}"
        return 0
    fi

    # download config.yml
    wget -t 2 -T 10 -O /tmp/config.yml ${CONFIG_URL} >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        echo -e "${red}下载config.yml失败，请检查本机能否连接 ${CONFIG_URL}${plain}"
        return 0
    fi

    # modify config.yml
    ## modify v2board info
    echo -e "> 修改v2board域名"
    read -e -r -p "请输入v2board域名（默认：${V2BOARD_URL}）：" input
    if [[ $input != "" ]]; then
        V2BOARD_URL=$input
    fi
    read -e -r -p "请输入v2board api key（默认：${V2BOARD_API_KEY}）：" input
    if [[ $input != "" ]]; then
        V2BOARD_API_KEY=$input
    fi
    V2BOARD_URL=$(echo $V2BOARD_URL | sed -e 's/[]\/&$*.^[]/\\&/g')
    V2BOARD_API_KEY=$(echo $V2BOARD_API_KEY | sed -e 's/[]\/&$*.^[]/\\&/g')
    sed -i "s/USER_V2BOARD_DOMAIN/${V2BOARD_URL}/g" /tmp/config.yml
    sed -i "s/USER_V2BOARD_API_KEY/${V2BOARD_API_KEY}/g" /tmp/config.yml
    echo -e "> 当前域名: ${green}${V2BOARD_URL}${plain}"
    echo -e "> 当前api key: ${green}${V2BOARD_API_KEY}${plain}"

    ## read NODE_ID
    read -e -r -p "请输入节点ID（必须与v2board设定的保持一致）：" input
    NODE_ID=$input
    echo -e "节点ID为: ${green}${NODE_ID}${plain}"
    sed -i "s/USER_NODE_ID/${NODE_ID}/g" /tmp/config.yml

    ## read NODE_TYPE
    echo -e "
    ${green}节点类型：${plain}
    ${green}1.${plain}  V2ray
    ${green}2.${plain}  ShadowSocks
    ${green}3.${plain}  Trojan
    "
    read -e -r -p "请输入选择[1-3]：" num
    case "$num" in
    1)
        NODE_TYPE="V2ray"
        ;;
    2)
        NODE_TYPE="Shadowsocks"
        ;;
    3)
        NODE_TYPE="Trojan"
        ;;
    *)
        echo -e "${red}请输入正确的选择[1-3]${plain}"
        exit 1
        ;;
    esac
    sed -i "s/USER_NODE_TYPE/${NODE_TYPE}/g" /tmp/config.yml && echo -e "成功修改节点类型为: ${green}${NODE_TYPE}${plain}"
    

    ## read tls
    echo -e "
    ${green}证书申请方式：${plain}
    ${green}1.${plain}  (none)不申请证书（如果使用nginx进行tls配置请选择此项）
    ${green}2.${plain}  (file)自备证书文件（之后在${green}${XRAYRPATH}/XrayR/cert/${plain}目录下修改）
    ${green}3.${plain}  (http)脚本通过http方式申请证书（需要提前解析域名到本机ip并开启80端口）
    ${green}4.${plain}  (dns)脚本通过dns方式申请证书（脚本暂时只支持cloudflare，需要cloudflare的global api key和email）
    "

    read -e -r -p "请输入选择[1-4]：" num
    case "$num" in
    1)
        echo -e "不申请证书"
        sed -i "s/USER_CERT_MODE/none/g" /tmp/config.yml
        ;;     
    2)
        echo -e "自备证书文件"
        echo -e "在${green}${XRAYRPATH}/XrayR/cert/${plain}目录下修改 ${green}节点域名.cert 节点域名.key${plain}文件）"
        sed -i "s/USER_CERT_MODE/file/g" /tmp/config.yml
        TLS=true
        ;;
    3)
        echo -e "脚本通过http方式申请证书"
        sed -i "s/USER_CERT_MODE/http/g" /tmp/config.yml
        TLS=true
        ;;
    4)
        echo -e "脚本通过dns方式申请证书"
        sed -i "s/USER_CERT_MODE/dns/g" /tmp/config.yml
        TLS=true
        read -e -r -p "请输入cloudflare的global api key：" input
        CLOUDFLARE_GLOBAL_API_KEY=$input
        read -e -r -p "请输入cloudflare的email：" input
        CLOUDFLARE_EMAIL=$input
        CLOUDFLARE_GLOBAL_API_KEY=$(echo $CLOUDFLARE_GLOBAL_API_KEY | sed -e 's/[]\/&$*.^[]/\\&/g')
        CLOUDFLARE_EMAIL=$(echo $CLOUDFLARE_EMAIL | sed -e 's/[]\/&$*.^[]/\\&/g')
        sed -i "s/USER_CLOUDFLARE_GLOBAL_API_KEY/${CLOUDFLARE_GLOBAL_API_KEY}/g" /tmp/config.yml
        sed -i "s/USER_CLOUDFLARE_EMAIL/${CLOUDFLARE_EMAIL}/g" /tmp/config.yml
        ;;
    *)
        echo -e "${red}输入错误，请重新输入[1-4]${plain}"
        if [[ $# == 0 ]]; then
        modify_xrayr_config
        else
            modify_xrayr_config 0
        fi
        exit 0
        ;;
    esac

    if [ -z "${TLS}" ]; then
        echo -e "> 不申请证书"
    else
        read -e -r -p "请输入域名：" input
        NODE_DOMAIN=$input
        echo -e "> 节点域名为: ${green}${NODE_DOMAIN}${plain}"
        sed -i "s/USER_NODE_DOMAIN/${NODE_DOMAIN}/g" /tmp/config.yml
    fi

    # replace config.yml
    mv /tmp/config.yml $XRAYR_PATH/config.yml
    mv /tmp/docker-compose.yml $XRAYR_PATH/docker-compose.yml
    echo -e "xrayr配置 ${green}修改成功，请稍等重启生效${plain}"
    # get NODE_IP
    NODE_IP=`curl -s https://ipinfo.io/ip`
    
    
    if [[ -z "${TLS}" ]]; then
        echo -e "> 不申请证书"
    else
        echo -e "> 节点域名为：${yellow}${NODE_DOMAIN}${plain}"
    fi
    echo -e "> 节点IP为：${yellow}${NODE_IP}${plain}"

    # show config
    show_config 0

    # restart xrayr
    restart_and_update 0

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    echo -e "> 启动xrayr"
    # start docker-compose
    cd $XRAYR_PATH && docker-compose up -d
    if [[ $? == 0 ]]; then
        echo -e "${green}启动成功${plain}"
    else
        echo -e "${red}启动失败，请稍后查看日志信息${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    echo -e "> 停止xrayr"

    cd $XRAYR_PATH && docker-compose down
    if [[ $? == 0 ]]; then
        echo -e "${green}停止成功${plain}"
    else
        echo -e "${red}停止失败，请稍后查看日志信息${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart_and_update() {
    echo -e "> 重启xrayr"
    cd $XRAYR_PATH
    docker-compose pull
    docker-compose down
    docker-compose up -d
    if [[ $? == 0 ]]; then
        echo -e "${green}重启成功${plain}"
    else
        echo -e "${red}重启失败，请稍后查看日志信息${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    echo -e "> 获取xrayr日志"

    cd $XRAYR_PATH && docker-compose logs -f

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_config() {
    echo -e "> 查看xrayr配置"

    cd $XRAYR_PATH
    
    V2BOARD_URL=$(cat config.yml | grep "ApiHost" | awk -F ':' '{print $2 $3}' | awk -F '"' '{print $2}')
    V2BOARD_API_KEY=$(cat config.yml | grep "ApiKey" | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
    NODE_ID=$(cat config.yml | grep "NodeId" | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
    NODE_TYPE=$(cat config.yml | grep "NodeType" | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
    CertMode=$(cat config.yml | grep "CertMode" | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
    CertFile=$(cat config.yml | grep "CertFile" | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
    KeyFile=$(cat config.yml | grep "KeyFile" | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
    NODE_DOMAIN=$(cat config.yml | grep "CertDomain" | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
    CLOUDFLARE_EMAIL=$(cat config.yml | grep "CloudflareEmail" | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
    CLOUDFLARE_API_KEY=$(cat config.yml | grep "CloudflareApiKey" | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')

    echo -e "
    > v2board配置为: 
    v2board前端域名：${green}${V2BOARD_URL}${plain}
    v2board api key：${green}${V2BOARD_API_KEY}${plain}
    节点IP：${green}${NODE_IP}${plain}
    节点ID：${green}${NODE_ID}${plain}
    节点类型：${green}${NODE_TYPE}${plain}
    证书模式：${green}${CertMode}${plain}
    证书文件：${green}${CertFile}${plain}
    私钥文件：${green}${KeyFile}${plain}
    节点域名：${green}${NODE_DOMAIN}${plain}
    Cloudflare Email：${green}${CLOUDFLARE_EMAIL}${plain}
    Cloudflare API Key：${green}${CLOUDFLARE_API_KEY}${plain}
    "
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

uninstall() {
    echo -e "> 卸载xrayr"

    cd $XRAYR_PATH && docker-compose down
    rm -rf $XRAYR_PATH
    docker rmi -f crackair/xrayr:latest > /dev/null 2>&1
    clean_all

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}* 按回车返回主菜单 *${plain}" && read temp
    show_menu
}

clean_all() {
    clean_all() {
    if [ -z "$(ls -A ${XRAYR_PATH})" ]; then
        rm -rf ${XRAYR_PATH}
    fi
}
}

show_menu() {
    echo -e "
    ${green}xrayr Docker安装管理脚本${plain}
    ${green}1.${plain}  安装xrayr
    ${green}2.${plain}  修改xrayr配置
    ${green}3.${plain}  启动xrayr
    ${green}4.${plain}  停止xrayr
    ${green}5.${plain}  重启并更新xrayr（没有更新版本啦！）
    ${green}6.${plain}  查看xrayr日志
    ${green}7.${plain}  查看xrayr配置
    ${green}8.${plain}  卸载xrayr
    ————————————————-
    ————————————————-
    ${green}0.${plain}  退出脚本
    "
    echo && read -ep "请输入选择 [0-7]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        install
        ;;
    2)
        modify_xrayr_config
        ;;
    3)
        start
        ;;
    4)
        stop
        ;;
    5)
        restart_and_update
        ;;
    6)
        show_log
        ;;
    7)
        show_config
        ;;
    8)
        uninstall
        ;;
    *)
        echo -e "${red}请输入正确的数字 [0-7]${plain}"
        ;;
    esac
}

pre_check
show_menu
