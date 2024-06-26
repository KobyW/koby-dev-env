#!/bin/bash

echo -e "Updating apt repos..."
sudo apt-get update 1> /dev/null
sudo apt-get install wget
sudo apt-get install unzip

wget https://github.com/dylanaraps/pfetch/archive/master.zip -O $HOME/.local/pfetch.zip
unzip $HOME/.local/pfetch.zip -d $HOME/.local/
rm -rf $HOME/.local/pfetch.zip

sudo install $HOME/.local/pfetch-master/pfetch /usr/local/bin/
ls -l /usr/local/bin/pfetch
rm -rf $HOME/.local/pfetch-master

echo -e "FINISHED"
pfetch
