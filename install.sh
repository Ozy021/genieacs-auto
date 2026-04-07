#!/bin/bash

echo "=== INSTALL GENIEACS AUTO FINAL ==="

# =========================
# UPDATE SYSTEM
# =========================
apt update -y && apt upgrade -y

# =========================
# INSTALL BASIC
# =========================
apt install -y curl gnupg build-essential software-properties-common

# =========================
# INSTALL MONGODB (AUTO FIX)
# =========================
if ! command -v mongod &> /dev/null
then
  apt install -y mongodb || apt install -y mongodb-server || true
fi

systemctl enable mongodb || true
systemctl start mongodb || true

# =========================
# INSTALL NODEJS
# =========================
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# =========================
# INSTALL GENIEACS
# =========================
npm install -g genieacs

# =========================
# CREATE USER
# =========================
useradd -r -s /bin/false genieacs 2>/dev/null

# =========================
# DIRECTORY
# =========================
mkdir -p /opt/genieacs/ext
mkdir -p /var/log/genieacs
mkdir -p /var/lib/genieacs-log

# =========================
# COPY CONFIG
# =========================
cp genieacs.env /opt/genieacs/genieacs.env

# =========================
# COPY EXT (SAFE)
# =========================
if [ -d "ext" ]; then
  cp -r ext/* /opt/genieacs/ext/
fi

# =========================
# COPY LOGO (AUTO DETECT UNIVERSAL)
# =========================
LOGO_FILE=$(find /usr /usr/local -name "logo-*.svg" 2>/dev/null | grep genieacs | head -n 1)

if [ -n "$LOGO_FILE" ]; then
  cp logo.svg "$LOGO_FILE"
fi

# =========================
# PERMISSION
# =========================
chown -R genieacs:genieacs /opt/genieacs
chown -R genieacs:genieacs /var/log/genieacs
chown -R genieacs:genieacs /var/lib/genieacs-log

# =========================
# SERVICE
# =========================
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

# =========================
# LOG CONFIG
# =========================
mkdir -p /etc/systemd/system/genieacs-cwmp.service.d

cat <<EOF > /etc/systemd/system/genieacs-cwmp.service.d/override.conf
[Service]
Environment=GENIEACS_LOG_DIR=/var/lib/genieacs-log
EOF

# =========================
# START SERVICE
# =========================
systemctl daemon-reload

systemctl enable genieacs-cwmp
systemctl enable genieacs-nbi
systemctl enable genieacs-ui
systemctl enable genieacs-fs

systemctl restart genieacs-cwmp
systemctl restart genieacs-nbi
systemctl restart genieacs-ui
systemctl restart genieacs-fs

# =========================
# DONE
# =========================
echo "====================================="
echo "INSTALL BERHASIL ✅"
echo "Akses: http://IP:3000"
echo "====================================="