#!/bin/bash

echo "=== INSTALL GENIEACS CUSTOM ==="

apt update -y && apt upgrade -y
apt install -y curl gnupg build-essential mongodb

curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

systemctl enable mongodb
systemctl start mongodb

npm install -g genieacs

useradd -r -s /bin/false genieacs 2>/dev/null

mkdir -p /opt/genieacs/ext
mkdir -p /var/log/genieacs
mkdir -p /var/lib/genieacs-log

# restore config
cp genieacs.env /opt/genieacs/genieacs.env

# restore ext
cp -r ext/* /opt/genieacs/ext/

# restore logo (auto detect)
LOGO_FILE=$(find /usr/lib/node_modules/genieacs/ -name "logo-*.svg" | head -n 1)

if [ -n "$LOGO_FILE" ]; then
  cp logo.svg "$LOGO_FILE"
fi

chown -R genieacs:genieacs /opt/genieacs
chown -R genieacs:genieacs /var/log/genieacs
chown -R genieacs:genieacs /var/lib/genieacs-log

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

systemctl restart genieacs-cwmp
systemctl restart genieacs-nbi
systemctl restart genieacs-ui
systemctl restart genieacs-fs

echo "=== SELESAI ==="
