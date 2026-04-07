#!/bin/bash

echo "=== INSTALL GENIEACS CUSTOM ==="

# UPDATE
apt update -y && apt upgrade -y

# INSTALL DEPENDENCY
apt install -y curl gnupg build-essential mongodb

# INSTALL NODEJS
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# START MONGODB
systemctl enable mongodb
systemctl start mongodb

# INSTALL GENIEACS
npm install -g genieacs

# USER
useradd -r -s /bin/false genieacs 2>/dev/null

# FOLDER
mkdir -p /opt/genieacs/ext
mkdir -p /var/log/genieacs
mkdir -p /var/lib/genieacs-log

# RESTORE CONFIG
cp genieacs.env /opt/genieacs/genieacs.env

# RESTORE EXT (AMAN)
if [ -d "ext" ]; then
  cp -r ext/* /opt/genieacs/ext/
fi

# RESTORE LOGO (AUTO DETECT)
LOGO_FILE=$(find /usr/lib/node_modules/genieacs/ -name "logo-*.svg" | head -n 1)

if [ -n "$LOGO_FILE" ]; then
  cp logo.svg "$LOGO_FILE"
fi

# PERMISSION
chown -R genieacs:genieacs /opt/genieacs
chown -R genieacs:genieacs /var/log/genieacs
chown -R genieacs:genieacs /var/lib/genieacs-log

# SERVICE
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

# START SERVICE
systemctl daemon-reload

systemctl enable genieacs-cwmp
systemctl enable genieacs-nbi
systemctl enable genieacs-ui
systemctl enable genieacs-fs

systemctl restart genieacs-cwmp
systemctl restart genieacs-nbi
systemctl restart genieacs-ui
systemctl restart genieacs-fs

echo "=== SELESAI ==="
echo "Akses UI: http://IP:3000"
