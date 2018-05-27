#!/bin/bash

#Variables - START
TARBALLURL="https://github.com/bulwark-crypto/Bulwark/releases/download/1.2.4/bulwark-1.2.4.0-linux64.tar.gz"
TARBALLNAME="bulwark-1.2.4.0-linux64.tar.gz"
BOOTSTRAPURL="https://github.com/bulwark-crypto/Bulwark/releases/download/1.2.4/bootstrap.dat.zip"
BOOTSTRAPARCHIVE="bootstrap.dat.zip"
BWKVERSION="1.2.4.0"
# BWK-Dash variables.
DASH_BIN_TAR="bwk-dash-1.0.0-linux-amd64.tar.gz"
DASH_HTML_TAR="bwk-dash-1.0.0-html.tar.gz"
DASH_PORT="8080"
DASH_VER="v1.0.0"
#Variables - END

#TODO: Combine back with SHN install script.
sudo apt-get install -y gcc unzip
sudo adduser bulwark

#Bulwark Service - START
sudo cat > /etc/systemd/system/bulwarkd.service << EOL
[Unit]
Description=Bulwarks's distributed currency daemon
After=network.target
[Service]
User=bulwark
Group=bulwark
WorkingDirectory=/home/bulwark
Type=forking
ExecStart=/usr/local/bin/bulwarkd -datadir=/home/bulwark/.bulwark -conf=/home/bulwark/.bulwark/bulwark.conf -daemon
ExecStop=/usr/local/bin/bulwark-cli -datadir=/home/bulwark/.bulwark -conf=/home/bulwark/.bulwark/bulwark.conf stop
#KillMode=process
Restart=always
TimeoutSec=120
RestartSec=30
[Install]
WantedBy=multi-user.target
EOL
sleep 1
#Bulwark Service - END

#Bulwark Config - START
sudo mkdir /home/bulwark/.bulwark
sudo touch /home/bulwark/.bulwark/bulwark.conf
sudo chown -R bulwark:bulwark /home/bulwark/.bulwark
RPCUSER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
RPCPASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
sudo cat > /home/bulwark/.bulwark/bulwark.conf << EOL
rpcuser=${RPCUSER}
rpcpassword=${RPCPASSWORD}
daemon=1
EOL
#Bulwark Config - END

#BWK-Dash Setup - START
# Setup systemd service and start.
sudo cat > /etc/systemd/system/bwk-dash.service << EOL
[Unit]
Description=Bulwark Home Node Dashboard
After=network.target
[Service]
User=bulwark
Group=bulwark
WorkingDirectory=/home/bulwark/dash
ExecStart=/usr/local/bin/bwk-dash
Restart=always
TimeoutSec=10
RestartSec=35
[Install]
WantedBy=multi-user.target
EOL
sleep 1
# Get binaries and install.
wget https://github.com/bulwark-crypto/bwk-dash/releases/download/$DASH_VER/$DASH_BIN_TAR
sudo tar -zxf $DASH_BIN_TAR -C /usr/local/bin
rm -f $DASH_BIN_TAR
# Copy the html files to the dash folder and create.
wget https://github.com/bulwark-crypto/bwk-dash/releases/download/$DASH_VER/$DASH_HTML_TAR
sudo mkdir -p /home/bulwark/dash
sudo tar -zxf $DASH_HTML_TAR -C /home/bulwark/dash
rm -f $DASH_HTML_TAR
# Create .env file for dashboard api and cron.
cat > /home/bulwark/dash/.env << EOL
DASH_DONATION_ADDRESS=TESTADDRESSHERE
DASH_PORT=${DASH_PORT}
DASH_RPC_ADDR=localhost
DASH_RPC_PORT=52541
DASH_RPC_USER=${RPCUSER}
DASH_RPC_PASS=${RPCPASSWORD}
DASH_WEBSITE=/home/bulwark/dash
DASH_DB=/home/bulwark/dash/bwk-dash.db
DASH_TOR=
EOL
sleep 1
# Cleanup/enforce ownership.
sudo chown -R bulwark:bulwark /home/bulwark/dash
# Setup timer and service for bwk-cron.
sudo cat > /etc/systemd/system/bwk-cron.service << EOL
[Unit]
Description=Bulwark Home Node Dashboard - Cron
After=network.target
[Service]
User=bulwark
Group=bulwark
WorkingDirectory=/home/bulwark/dash
ExecStart=/usr/local/bin/bwk-cron
Restart=always
TimeoutSec=10
RestartSec=35
EOL
sleep 1
sudo cat > /etc/systemd/system/bwk-cron.timer << EOL
[Unit]
Description=Bulwark Home Node Dashboard - Cron
[Timer]
OnBootSec=35
OnUnitActiveSec=60
[Install]
WantedBy=timers.target
EOL
sleep 1
# Enable service and timer.
sudo systemctl enable bwk-cron.timer
sudo systemctl enable bwk-dash.service
#BWK-Dash Setup - END

#Bulwark Node - START
sudo wget $TARBALLURL
sleep 2
sudo tar -xzf $TARBALLNAME -C /usr/local
sudo rm $TARBALLNAME
sleep 3
cd ~
sudo chown -R bulwark:bulwark /home/bulwark/bulwark/
sleep 1
sudo systemctl enable bulwarkd.service
sleep 1
#Bulwark Node - END

sudo reboot
