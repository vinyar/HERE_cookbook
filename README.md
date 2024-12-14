# Overview

This repository is work related to setting up HERE (here.com) server dev work station.

# Validation - Cloud
inspec exec .\here_server_validation.rb -t ssh://centos@3.234.244.161 --key-files .\alex.pem

# Validation - Local
inspec exec .\here_server_validation.rb -t ssh://vagrant@127.0.0.1:2222 --key-files C:/Users/alvin/.vagrant.d/boxes/CentOS7-with-chef/0/virtualbox/vagrant_private_key

Replace relevant pieces with your local parts.
For vagrant, get information via `vagrant ssh-config`

# Repository Directories

- `cookbooks/` - Cookbook dependencies via `berks vendor ./cookbooks`

# Configuration

install virtualbox  
install chef workstation  
download HERE server bits using your account  
download java for HERE  
download tomcat for HERE  


# Next Steps

Right now mounted folders are specific to MY machine and will most definitely not work for you. (feel free to add PR with remote_file to download bits from a known good long-term location)
Chef Cookbook is very simple. I didn't want to fight Tomcat or java cookbooks as they seem to be either end of life, abandoned, or require too much troubleshooting.  
