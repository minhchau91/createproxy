#!/bin/bash

new_password=danielchau@123#
echo "root:$new_password" | sudo chpasswd
if [ $? -eq 0 ]; then
    echo "Changed passwd success"
else
    echo "Changed passwd failed"
fi
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sudo service ssh restart
