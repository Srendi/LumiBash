#/bin/bash

#A bash script that will:
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
	add-apt-repository -y ppa:saltstack/salt
	apt-get update
	apt-get install -y salt-master salt-minion salt-ssh salt-cloud salt-doc

	# Open firewall
	ufw allow salt

	# Installed. Now restart servces
	restart salt-master
	restart salt-minion

	# Setup minion keys
	salt-key --list all
	salt-call key.finger --local
	salt-key -y -a ubuntu
}

install_packages() {
	# Ubuntu12.04 default apt-get bug
	rm -rf /var/lib/apt/lists/*
	apt-get update
	#Install deps
	apt-get install -y python-software-properties
	apt-get install -y software-properties-common
	add-apt-repository -y ppa:fkrull/deadsnakes-python2.7
	apt-get update
	apt-get install -y python2.7
	#apt-get -y upgrade
	apt-get install -y git
	apt-get install -y msgpack-python python-crypto
	# Config directory for salt
	mkdir -p /srv/salt
	mkdir -p /srv/pillar
	mkdir -p /srv/formulas
	mkdir -p /srv/salt/prod
	mkdir -p /srv/salt/dev
	mkdir -p /srv/salt/qa
	#Pull master/minion cfg
	cd /srv/salt/
	git clone https://github.com/Srendi/LumiDeployFlask.git
	mkdir -p /etc/salt/master.d/
	mkdir -p /etc/salt/minion.d/
	cp /srv/salt/LumiDeployFlask/files/etc/salt/minion.d/minion.conf /etc/salt/minion.d/
	cp /srv/salt/LumiDeployFlask/files/etc/salt/master.d/master.conf /etc/salt/master.d/

}
run_highstate() {
	salt '*' state.apply
}

deploy_app() {
	mkdir /var/www/
	cd /var/www/
	git clone https://github.com/Srendi/LumiFlaskBlog.git
}

start_app() {
	cd /var/www/LumiFlaskBlog
	gunicorn -w 4 -b 127.0.0.1:5000 $usedApp
}

#Main
if [ $(id -u) -ne '0' ]
then
	echo "This must be run with root priveleges"
fi

install_packages
install_salt
run_highstate
deploy_app
start_app