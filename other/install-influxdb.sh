#!/bin/bash
# Install influx db
sudo apt-get update
wget -q https://repos.influxdata.com/influxdata-archive_compat.key
echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo te>
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list
sudo apt-get update
sudo apt-get install influxdb

echo "Version of db is $(influx version)"

#Start influx as a service
sudo systemctl start influxdb
sudo systemctl enable influxdb

echo "Service status is $(sudo service influxdb status)"

sudo ufw allow 8086/tcp

