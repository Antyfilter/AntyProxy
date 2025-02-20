echo "telegram proxy install.sh $*"

apt install -y python3 python3-uvloop python3-cryptography python3-socks libcap2-bin
useradd --no-create-home -s /usr/sbin/nologin tgproxy

git clone https://github.com/alexbers/mtprotoproxy 
cd  mtprotoproxy
if [[ "$1" ]]; then
sed -i "s/00000000000000000000000000000001/$1/g" config.py
fi
echo 'TLS_DOMAIN = "mail.google.com"'>> config.py
sed -i 's/PORT = 443/PORT = 449/g' config.py

ln -s  $(pwd)/../mtproxy.service /etc/systemd/system/
systemctl enable mtproxy.service
systemctl start mtproxy.service

IP=$(curl -Lso- https://api.ipify.org);

echo "https://t.me/proxy?server=$IP&port=443&secret=ee$16d61696c2e676f6f676c652e636f6d">use-link
