# !/bin/bash
#
# 自动下载静态伪装网站到指定目录

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
export PATH=$PATH:/usr/local/bin


WEB_ROOT=$1
if [ -z "$WEB_ROOT" ]; then
    echo "用法: $0 网站root目录"
    echo -e "${red}未输入目录值，将使用默认值: /var/www/html${plain}"
    WEB_ROOT="/var/www/html"
    echo -e "是否继续？[Y/n]"
    read -p "(默认: y):" yn
    [ -z "${yn}" ] && yn="y"
    if [[ $yn == [Yy] ]]; then
        echo -e "${green}继续执行${plain}"
    else
        echo -e "${red}退出执行${plain}"
        exit 1
    fi
fi

if [ ! -d "$WEB_ROOT" ]; then
    echo -e "${red}错误！目录不存在${plain}"
    exit 1
fi

# 下载静态伪装网站
# static html resource url list
STATIC_HTML_URL_LIST=(
    "https://chomp.webflow.io/"
    "https://playo-128.webflow.io/"
    "https://aquapure-wbs.webflow.io/"
    "https://inspiration-template.webflow.io/"
    "https://accomplishedtemplate.webflow.io/"
    "https://north-template.webflow.io/"
    "https://sign-template.webflow.io/"
)
# randomly choose one
STATIC_HTML_URL=${STATIC_HTML_URL_LIST[$RANDOM % ${#STATIC_HTML_URL_LIST[@]} ]}
echo -e "${green}Download static html resource from: ${STATIC_HTML_URL}${plain}"

# download static html resource to web root
# check if wget is installed
if [ ! -x "$(command -v wget)" ]; then
    echo -e "${red}Error: wget is not installed.${plain}"
    # install wget
    echo -e "${green}Install wget...${plain}"
    # check OS
    if [ -f /etc/redhat-release ]; then
        # install wget on CentOS
        yum install -y wget
    elif cat /etc/issue | grep -q -E -i "debian"; then
        # install wget on Debian/Ubuntu
        apt-get update
        apt-get install -y wget
    elif cat /etc/issue | grep -q -E -i "ubuntu"; then
        # install wget on Ubuntu
        apt-get update
        apt-get install -y wget
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
        # install wget on CentOS
        yum install -y wget
    fi
fi
# 下载静态伪装网站，index.html
wget -O ${WEB_ROOT}/index.html ${STATIC_HTML_URL}

echo -e "${green}下载完成，下载文件在 ${WEB_ROOT}/index.html${plain}"
