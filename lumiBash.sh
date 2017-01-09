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
	logger -s "Gavin: Installing Salt"
	cd /tmp
#	curl -o bootstrap-salt.sh -L https://bootstrap.saltstack.com
#	sh bootstrap-salt.sh -M -N git develop
	sudo add-apt-repository -y ppa:saltstack/salt
	sudo apt-get update
#	sudo apt-get install -y salt-master salt-minion
	sudo apt-get install -y salt-minion
	sudo apt-get install -y salt-ssh salt-cloud salt-doc
	logger -s "Gavin: Salt installled"

	# Open firewall
	sudo ufw allow salt
	logger -s "Gavin: Salt Firewall opened"
	# Installed. Now restart servces
	sudo stop salt-minion
#	sudo stop salt-master
	sleep 3
#	sudo start salt-master
	sudo start salt-minion
	sleep 3
	logger -s "Gavin: Salt Started"
	# Setup minion keys
#	sudo salt-key --list all
#	sudo salt-call key.finger --local
#	sudo salt-key -y -A
	sleep 3
	logger -s "Gavin: Salt Minion key accepted"
}

install_packages() {
	logger -s "Gavin: Installing Packages"
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
	logger -s "Gavin: Packages Installed"
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
	logger -s "Gavin: LumiDeployFlask Installed"
	sudo mkdir -p /etc/salt/master.d/
	sudo mkdir -p /etc/salt/minion.d/
	sudo cp /srv/salt/LumiDeployFlask/salt/files/etc/salt/minion.d/minion.conf /etc/salt/minion.d/
	#sudo cp /srv/salt/LumiDeployFlask/salt/files/etc/salt/master.d/master.conf /etc/salt/master.d/
	logger -s "Gavin: Package Directories Created"
}

install_pip() {
	sudo apt-get install -y python-pip
	sudo pip install virtualenv
	sudo apt-get install -y python-virtualenv
	sudo pip install Flask
	sudo pip install --upgrade pip setuptools
	sudo pip install gunicorn
}

install_nginx() {
	sudo apt-get install -y nginx
	sudo mkdir -p /etc/nginx/conf.d/
	sudo cp /srv/salt/LumiDeployFlask/nginx/files/etc/nginx/conf.d/nginx.conf /etc/nginx/conf.d/
	sudo /etc/init.d/nginx restart
}

run_highstate() {
logger -s "Gavin: Restarting Salt Prior to calling highstate"
	sudo stop salt-minion
#	sudo stop salt-master
	sleep 3
#	sudo start salt-master
	sudo start salt-minion
	sleep 10
	logger -s "Gavin: Calling Salt highstate"
	echo "Calling salt highstate"
	cd /srv/salt/LumiDeployFlask/
#	sudo salt '*' state.apply
	salt-call --local state.apply
	sleep 3
	logger -s "Gavin: Salt highstate applied"
}

deploy_app() {
	logger -s "Gavin: Deploying App"
	cd /var/www/
	sudo git clone https://github.com/Srendi/LumiFlaskBlog.git
	cd /var/www/LumiFlaskBlog/
	sudo git pull
	logger -s "Gavin: App Deployed"
}

start_app() {
	logger -s "Gavin: Starting gunicorn"
	cd /var/www/LumiFlaskBlog
	sudo gunicorn -w 4 -b 127.0.0.1:5000 $usedApp &
	logger -s "Gavin: gunicorn started"
}

#Main
if [ $(id -u) -ne '0' ]
then
	echo "This must be run with root priveleges"
	touch ~/PleaseRunLumiBashwithRootPrivs
fi

install_packages
install_salt
install_nginx
install_pip
#run_highstate
deploy_app
start_app