#!/usr/bin/env bash
set -xe
sudo apt-get install -y git
cd ~
git clone https://github.com/Srendi/LumiBash.git
cd ~/LumiBash
sudo chmod a+x ./lumiBash.sh
sudo ./lumiBash.sh