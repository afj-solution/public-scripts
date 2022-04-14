#!/bin/bash
CHROME_PATH=$1
GECKO_PATH=$2
HUB_PATH=$3
NODE_PATH=$4
APPIUM_PATH=$5

nohup java -jar /usr/local/selenium/bin/selenium-standalone-server-4.1.2.jar hub -Dwedriver.chrome.driver=$CHROME_PATH -Dwedriver.gecko.driver=$GECKO_PATH --config $HUB_PATH > hub.log 2&1
echo "Started hub"
nohup java -jar /usr/local/selenium/bin/selenium-standalone-server-4.1.2.jar node --config $NODE_PATH > node.log 2&1
echo "Started node"
nohup java -jar /usr/local/selenium/bin/selenium-standalone-server-4.1.2.jar node --config $NODE_PATH > node-appium.log 2&1
nohup appium --allow-cors > appium.log 2&1
echo "Started appium"