#!/bin/bash

sudo rm -rf /var/log/user_management.log
sudo rm -rf /var/secure/user_passwords.csv

sudo userdel -r light
sudo userdel -r mayowa
sudo userdel -r idimma
