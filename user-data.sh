#!/usr/bin/env bash
sudo apt-get install -y git
cd ~
git clone https://github.com/Srendi/LumiBash.git
cd ~/LumiBash
sudo chmod a+x ./lumiBash.sh
PUBLIC_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null`
until $(curl --output /dev/null --silent --head --fail http://$PUBLIC_IP:80); do
	sudo ./lumiBash.sh
    sleep 5
done
