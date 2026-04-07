#!/bin/bash

echo "=== INSTALL GENIEACS + MONGODB AUTO ==="

apt update -y && apt upgrade -y

apt install -y curl gnupg build-essential

curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

apt install -y mongodb
systemctl enable mongodb
systemctl start mongodb

npm install -g genieacs

useradd -r -s /bin/false genieacs

mkdir -p /opt/genieacs/ext
mkdir -p /var/log/genieacs
mkdir -p /var/lib/genieacs-log

chown -R genieacs:genieacs /opt/genieacs
chown -R genieacs:genieacs /var/log/genieacs
chown -R genieacs:genieacs /var/lib/genieacs-log

cat <<EOF > /opt/genieacs/genieacs.env
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml

GENIEACS_EXT_DIR=/opt/genieacs/ext
NODE_OPTIONS=--enable-source-maps

GENIEACS_MONGODB_CONNECTION_URL=mongodb://127.0.0.1/genieacs

GENIEACS_UI_JWT_SECRET=CHANGE_ME_SECRET
EOF

create_service () {
cat <<EOF > /etc/systemd/system/genieacs-$1.service
[Unit]
Description=GenieACS $1
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-$1
Restart=always

[Install]
WantedBy=default.target
EOF
}

create_service cwmp
create_service nbi
create_service ui
create_service fs

mkdir -p /etc/systemd/system/genieacs-cwmp.service.d

cat <<EOF > /etc/systemd/system/genieacs-cwmp.service.d/override.conf
[Service]
Environment=GENIEACS_LOG_DIR=/var/lib/genieacs-log
EOF

systemctl daemon-reload

systemctl enable genieacs-cwmp
systemctl enable genieacs-nbi
systemctl enable genieacs-ui
systemctl enable genieacs-fs

systemctl start genieacs-cwmp
systemctl start genieacs-nbi
systemctl start genieacs-ui
systemctl start genieacs-fs

echo "=== INSTALL SELESAI ==="
echo "Akses UI: http://IP:3000"
