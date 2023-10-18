# 基于docker部署XrayR的一键脚本
## 使用
使用方法：
```bash
curl -L https://raw.githubusercontent.com/tech-fever/xrayr-docker-script/main/xrayr.sh -o xrayr.sh && chmod +x xrayr.sh && ./xrayr.sh
```

目前只在ubuntu 20.04 LTS 上实验过，不保证可用性。

2022年12月17日更新：
最近xrayr和v2board都有较大更新，本脚本也相应进行了更新。对于在这之前用过脚本想要更新到新版的，请使用
```bash
bash <(curl -sL https://raw.githubusercontent.com/tech-fever/xrayr-docker-script/main/update.sh)
```

2022年10月17日更新：
- 新增 `custom_outbound.json`


## 支持

- [x] 仅测试过v2board
- [x] 支持V2ray ShadowSocks Trojan
- [x] 支持设置有无证书三种证书申请方式：`dns file http`，其中 `dns` 证书申请仅支持Cloudflare dns
- [x] 支持查看xrayr配置

## 使用效果

```shell
xrayr Docker安装管理脚本
    1.  安装xrayr
    2.  修改xrayr配置
    3.  启动xrayr
    4.  停止xrayr
    5.  重启并更新xrayr（没有更新版本啦！）
    6.  查看xrayr日志
    7.  查看xrayr配置
    8.  卸载xrayr
    9.  安装bbr
    ————————————————
    0.  退出脚本
```

# 随机下载静态网站模板脚本
自动下载静态伪装网站到指定目录，默认会下载到 `/var/www/html`
```
curl -L https://raw.githubusercontent.com/tech-fever/xrayr-docker-script/main/nginx/fakewebsite.sh -o fakewebsite.sh && chmod +x fakewebsite.sh && ./fakewebsite.sh
```

如果要指定目录：
```
curl -L https://raw.githubusercontent.com/tech-fever/xrayr-docker-script/main/nginx/fakewebsite.sh -o fakewebsite.sh && chmod +x fakewebsite.sh && ./fakewebsite.sh 你需要存放静态网站资源的目录
```

目前是随机在这下面几个模板中下载：
```
STATIC_HTML_URL_LIST=(
    "https://chomp.webflow.io/"
    "https://playo-128.webflow.io/"
    "https://aquapure-wbs.webflow.io/"
    "https://inspiration-template.webflow.io/"
    "https://accomplishedtemplate.webflow.io/"
    "https://north-template.webflow.io/"
    "https://sign-template.webflow.io/"
)
```

# 审计

## rulelist 屏蔽
中国域名、Fake News和轮子域名的屏蔽列表

https://github.com/Rakau/blockList

代码：
```
wget https://raw.githubusercontent.com/Rakau/blockList/main/blockList -O /opt/xrayr/XrayR/rulelist
```

## 路由规则
参见 Xrayr 文件夹下的文件

geoip 下载地址：https://github.com/Loyalsoldier/geoip/releases/latest

