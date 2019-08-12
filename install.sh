#!/bin/bash
shopt -s expand_aliases

scriptDir=$(cd $(dirname $0) && pwd)

function print_msg_org(){
  printf "\e[33m$1\e[m\n"
}
function print_msg_error(){
  printf "\e[31m$1\e[m\n"
}

function print_msg_ble(){
  printf "\e[36m$1\e[m\n"
}

function mkdir_error(){
    print_msg_error '"~/laraquery" dirctory has already exist!\n'
    exit
}

print_msg_org "LaraQuery install..."

mkdir ~/laraquery 2>/dev/null || mkdir_error
cp -pR $scriptDir/. ~/laraquery  && print_msg_ble "Succeed Installation!"

if [[ -e ~/.bashrc ]]; then
    sudo echo "
#laraQuery" >> ~/.bashrc  && echo 'alias laraquery="bash ~/laraquery/larainstaller.sh"' >> ~/.bashrc
    source ~/.bashrc && print_msg_ble "Setting ~/.bashrc Succeed"
else
    touch ~/.bashrc
    sudo echo "
#laraQuery" >> ~/.bashrc  && echo 'alias laraquery="bash ~/laraquery/larainstaller.sh"' >> ~/.bashrc
    source ~/.bashrc && print_msg_ble "Setting ~/.bashrc Succeed"
fi
