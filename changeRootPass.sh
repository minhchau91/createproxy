#!/bin/bash
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
new_password=danielchau@123#
echo "root:$new_password" | sudo chpasswd
if [ $? -eq 0 ]; then
    echo "Changed passwd success"
else
    echo "Changed passwd failed"
fi
sudo service ssh restart

