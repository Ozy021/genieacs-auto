#!/bin/bash

echo "=== INSTALL GENIEACS AUTO FINAL ==="

WORKDIR="/root/genieacs-auto"

# =========================
# DOWNLOAD FILE DARI GITHUB
# =========================
cd /root
rm -rf genieacs-auto
git clone https://github.com/Ozy021/genieacs-auto.git
cd $WORKDIR

# =========================
# UPDATE SYSTEM
# =========================
apt update -y && apt upgrade -y

# =========================
# BASIC PACKAGE
# =========================
apt install -y curl gnupg build-essential software-properties-common git

# =========================
# INSTALL MONGODB (SAFE)
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
# USER
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
cp $WORKDIR/genieacs.env /opt/genieacs/genieacs.env

# =========================
# COPY EXT
# =========================
if [ -d "$WORKDIR/ext" ]; then
  cp -r $WORKDIR/ext/* /opt/genieacs/ext/
fi

# =========================
# COPY LOGO (AUTO DETECT)
# =========================
LOGO_FILE=$(find /usr /usr/local -name "logo-*.svg" 2>/dev/null | grep genieacs | head -n 1)

if [ -n "$LOGO_FILE" ]; then
  cp $WORKDIR/logo.svg "$LOGO_FILE"
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

echo "====================================="
echo "INSTALL BERHASIL ✅"
echo "Akses: http://IP:3000"
echo "====================================="