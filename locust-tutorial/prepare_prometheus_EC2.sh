#!/bin/bash

wget https://github.com/afj-solution/public-scripts/raw/master/other/install-docker.sh
wget https://github.com/afj-solution/public-scripts/raw/master/locust-tutorial/update_prometheus.py
sudo apt install -y python3-pip python3-pyyaml wget
chmod +x install-docker.sh
./install-docker.sh

python3 update_prometheus.py 

nohup sudo docker run -p 9090:9090 -v $PWD/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus > prometheus.log 2>&1 &