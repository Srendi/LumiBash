#!/usr/bin/env bash

# Install Salt
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update
sudo apt-get install -y python-software-properties
sudo apt-get install -y software-properties-common 
sudo add-apt-repository -y ppa:saltstack/salt
sudo apt-get update
sudo apt-get install -y salt-minion
sudo apt-get install -y salt-ssh salt-cloud salt-doc
sudo apt-get install -y git

#Pull master/minion cfg
sudo mkdir -p /srv/salt/
cd /srv/salt/
sudo git clone https://github.com/Srendi/LumiDeployFlask.git
sudo cp /srv/salt/LumiDeployFlask/salt/files/etc/salt/minion /etc/salt/minion.d/minion.conf

# Installed and config update. Now restart servces
sudo stop salt-minion
sleep 5
sudo start salt-minion
sleep 10

#Call saltstate
cd /srv/salt/LumiDeployFlask/
sudo salt-call --local state.apply