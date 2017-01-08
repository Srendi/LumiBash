#/bin/bash

#A bash script that will:
#	Be called on aws ec2 first create to install salt.
#   Partner script will Launch the EC2 server using aws cli utilities and AMI ami-020a0f61.
#	Begin the configuration management / bootstrapping of the server using a SaltMaster (preferred) or using a masterless setup.
#
# lumiBash.sh <app> <environment> <num_servers> <server_size>
# ex: lumiBash.sh hello_world dev 1 t1.micro

# Install SaltMaster and Salt Minion from latest git
install_salt() {
	cd /tmp
#	curl -o bootstrap-salt.sh -L https://bootstrap.saltstack.com
#	sh bootstrap-salt.sh -M -N git develop
	add-apt-repository ppa:saltstack/salt
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
	salt-key -f saltmaster
	salt-key -f salt-master
	salt-key -f salt-minion
}

install_packages() {
	# Ubuntu12.04 default apt-get bug
	rm -rf /var/lib/apt/lists/*
	apt-get update
	#Install deps
	apt-get install -y python-software-properties
	apt-get install -y software-properties-common
	add-apt-repository ppa:fkrull/deadsnakes-python2.7
	apt-get update
	apt-get install -y python2.7
	apt-get -y upgrade
	apt-get install -y git
	apt-get install -y msgpack-python python-crypto
	# Config directory for salt
	mkdir -p /srv/{salt,pillar}
	#Pull master/minion cfg
	cd /srv/salt/
	git clone https://github.com/Srendi/LumiDeployFlask.git
}
run_highstate() {
	salt '*' state.apply
}

deploy_app() {
	mkdir /var/www/helloapp
	cd /var/www/helloapp
	git clone https://github.com/Srendi/LumiFlaskBlog.git
}

start_app() {
	cd /var/www/helloapp
	gunicorn -w 4 -b 127.0.0.1:5000 hello:app
}

#Main
if [ $(id -u) -ne '0' ]
then
	echo "This must be run with root priveleges"
	exit(1)
fi

install_packages
install_salt
run_highstate
deploy_app
start_app