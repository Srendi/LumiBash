#!/usr/bin/env bash
# A bash script that will:
#	Be called on aws ec2 first create to install salt.
#   Partner script will Launch the EC2 server using aws cli utilities and AMI ami-020a0f61.
#	Begin the configuration management / bootstrapping of the server using a SaltMaster (preferred) or using a masterless setup.
#
# lumiBash.sh <app> <environment> <num_servers> <server_size>
# ex: lumiBash.sh hello_world dev 1 t1.micro

#Defaults
defaultApp="hello:app"
usedApp=$defaultApp
usedAppChanged=0

# Install SaltMaster and Salt Minion from latest git
install_salt() {
	cd /tmp
#	curl -o bootstrap-salt.sh -L https://bootstrap.saltstack.com
#	sh bootstrap-salt.sh -M -N git develop
	sudo add-apt-repository -y ppa:saltstack/salt
	sudo apt-get update
	sudo apt-get install -y salt-master salt-minion salt-ssh salt-cloud salt-doc

	# Open firewall
	sudo ufw allow salt

	# Installed. Now restart servces
	sudo restart salt-master
	sudo restart salt-minion

	# Setup minion keys
	sudo salt-key --list all
	sudo salt-call key.finger --local
	sudo salt-key -y -A
	sleep 3
}

install_packages() {
	# Ubuntu12.04 default apt-get bug
	sudo rm -rf /var/lib/apt/lists/*
	sudo apt-get update
	#Install deps
	sudo apt-get install -y python-software-properties
	sudo apt-get install -y software-properties-common
	sudo add-apt-repository -y ppa:fkrull/deadsnakes-python2.7
	sudo apt-get update
	sudo apt-get install -y python2.7
	#apt-get -y upgrade
	sudo apt-get install -y git
	sudo apt-get install -y msgpack-python python-crypto
	# Config directory for salt
	sudo mkdir -p /srv/salt
	sudo mkdir -p /srv/pillar
	sudo mkdir -p /srv/formulas
	sudo mkdir -p /srv/salt/prod
	sudo mkdir -p /srv/salt/dev
	sudo mkdir -p /srv/salt/qa
	#Pull master/minion cfg
	cd /srv/salt/
	sudo git clone https://github.com/Srendi/LumiDeployFlask.git
	cd /srv/salt/LumiDeployFlask/
	sudo git pull
	sudo mkdir -p /etc/salt/master.d/
	sudo mkdir -p /etc/salt/minion.d/
	sudo cp /srv/salt/LumiDeployFlask/salt/files/etc/salt/minion.d/minion.conf /etc/salt/minion.d/
	sudo cp /srv/salt/LumiDeployFlask/salt/files/etc/salt/master.d/master.conf /etc/salt/master.d/
	sudo mkdir -p /etc/nginx/conf.d/
	sudo cp /srv/salt/LumiDeployFlask/nginx/files/etc/nginx/conf.d/nginx.conf /etc/nginx/conf.d/
}

run_highstate() {
	sudo restart salt-master
	sleep 3
	sudo restart salt-minion
	sleep 3
	echo "Calling salt highstate"
	cd /srv/salt/LumiDeployFlask/
	sudo salt '*' state.apply
	sleep 3
}

deploy_app() {
	cd /var/www/
	sudo git clone https://github.com/Srendi/LumiFlaskBlog.git
	cd /var/www/LumiFlaskBlog/
	sudo git pull
}

start_app() {
	cd /var/www/LumiFlaskBlog
	sudo gunicorn -w 4 -b 127.0.0.1:5000 $usedApp &
}

#Main
if [ $(id -u) -ne '0' ]
then
	echo "This must be run with root priveleges"
	touch ~/PleaseRunLumiBashwithRootPrivs
fi

install_packages
install_salt
run_highstate
deploy_app
start_app