#!/usr/bin/env bash

# Instll Salt
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update
sudo apt-get install -y python-software-properties
sudo apt-get install -y software-properties-common 
sudo add-apt-repository -y ppa:saltstack/salt
sudo apt-get update
sudo apt-get install -y salt-minion
sudo apt-get install -y salt-ssh salt-cloud salt-doc

# Installed. Now restart servces
sudo stop salt-minion
sleep 3
sudo start salt-minion

#Pull master/minion cfg
sudo mkdir -p /srv/salt/
cd /srv/salt/
sudo git clone https://github.com/Srendi/LumiDeployFlask.git

#Call saltstate
cd /srv/salt/LumiDeployFlask/
sudo salt-call --local state.apply