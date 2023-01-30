#!/bin/bash
sudo apt install -y python3-pip python3-locust wget

wget https://github.com/afj-solution/public-scripts/raw/master/other/install-docker.sh
chmod +x install-docker.sh
./install-docker.sh

nohup sudo docker run -d --net=host containersol/locust_exporter > exporter.log 2>&1 &

wget https://github.com/afj-solution/public-scripts/raw/master/locust-tutorial/locustfile.py
nohup locust --master --master-bind-port=8080 -H https://api-dev.buy-it.afj-solution.com/api/v1 > locust.log 2>&1 &
