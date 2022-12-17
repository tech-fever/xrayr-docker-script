# !/bin/bash

# 升级脚本

xrayr_path="/opt/xrayr"
old_config_file="$xrayr_path/config.yml"
new_config_file="$xrayr_path/XrayR/config.yml"


# Check if the xrayr_path exists, if it does not exist, then exit
if [ ! -d "$xrayr_path" ]; then
  echo "xrayr似乎未安装，请检查后重试"
  exit
fi

# check if old config file exists
if [ ! -f "$old_config_file" ]; then
  echo "xrayr似乎未安装，请检查后重试"
  exit
fi

# check if xrayr_path directory exists docker-compose.yml
if [ ! -f "$xrayr_path/docker-compose.yml" ]; then
  echo "xrayr似乎未安装，请检查后重试"
  exit
fi

# check if xrayr_path directory exists XrayR
if [ ! -d "$xrayr_path/XrayR" ]; then
  echo "xrayr似乎未安装完全，请检查后重试"
  exit
fi

# check if xrayr_path directory exists XrayR/config.yml
if [ ! -f "$xrayr_path/XrayR/config.yml" ]; then
  echo "xrayr似乎已经升级，请检查后重试"
  exit
fi

# mv old_config_file to new_config_file
mv $old_config_file $new_config_file

# remove old config file
rm -rf $old_config_file

# get new docker-compose.yml
DC_YML_URL="https://raw.githubusercontent.com/tech-fever/xrayr-docker-script/main/docker-compose.yml"
wget -O $xrayr_path/docker-compose.yml $DC_YML_URL

# update and restart
cd $xrayr_path
docker-compose pull
docker-compose down
docker-compose up -d

# check if xrayr container is running
if [ "$(docker inspect -f {{.State.Running}} xrayr)" = "true" ]; then
  echo "xrayr升级成功"
else
  echo "xrayr升级失败，请检查后重试"
fi
