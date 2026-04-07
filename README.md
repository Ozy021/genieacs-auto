Ganti JWT dengan yang baru

Di file yang kamu buka sekarang:

nano /opt/genieacs/genieacs.env

Ganti ini:
GENIEACS_UI_JWT_SECRET=CHANGE_ME_SECRET

Jalankan ini di terminal:
openssl rand -hex 64

Contoh hasil:
a8f3c9d1e5b7f2...

Masukkan jadi:
GENIEACS_UI_JWT_SECRET=a8f3c9d1e5b7f2...
Lalu Simpan

Tekan:
CTRL + X
Y
ENTER


Restart service
systemctl daemon-reload

systemctl restart genieacs-cwmp
systemctl restart genieacs-nbi
systemctl restart genieacs-ui
systemctl restart genieacs-fs
