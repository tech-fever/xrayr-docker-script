# 基于docker部署XrayR作者原版的一键脚本

使用方法：
```bash
bash <(curl -sL https://raw.githubusercontent.com/tech-fever/xrayr-docker-script/main/xrayr.sh)
```

目前只在ubuntu 20.04 LTS 上实验过，不保证可用性。

# 支持

- [x] 仅支持v2board
- [x] 支持V2ray ShadowSocks Trojan
- [x] 支持设置有无证书三种证书申请方式：`dns file http`，其中 `dns` 证书申请仅支持Cloudflare dns
- [x] 支持查看xrayr配置

# 使用效果

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
    ————————————————
    0.  退出脚本
```
