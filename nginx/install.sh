echo "nginx install.sh $*"

USER_SECRET=$1
DOMAIN=$2
IP=$(curl -Lso- https://api.ipify.org);
echo $IP
guid="${1:0:8}-${1:8:4}-${1:12:4}-${1:16:4}-${1:20:12}"
cloudprovider=${4:-$DOMAIN}

apt-get install -y nginx certbot python3-certbot-nginx


rm /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default

ln -s $(pwd)/web.conf /etc/nginx/conf.d/web.conf
mkdir -p /etc/nginx/stream.d/ 
ln -s $(pwd)/sni-proxy.conf /etc/nginx/stream.d/sni-proxy.conf
ln -s $(pwd)/signal.conf /etc/nginx/stream.d/signal.conf

if ! grep -Fxq "stream{include /etc/nginx/stream.d/*.conf;}" /etc/nginx/nginx.conf; then
  echo "stream{include /etc/nginx/stream.d/*.conf;}">>/etc/nginx/nginx.conf;
fi

sed -i "s/defaultusersecret/$USER_SECRET/g" common.conf
sed -i "s/defaultusersecret/$USER_SECRET/g" replace.conf
sed -i "s/defaultuserguidsecret/$guid/g" replace.conf
sed -i "s/defaultcloudprovider/$cloudprovider/g" replace.conf
sed -i "s/defaultserverip/$IP/g" replace.conf

sed -i "s/defaultserverhost/$DOMAIN/g" web.conf
sed -i "s/defaultserverhost/$DOMAIN/g" sni-proxy.conf

openssl req -x509 -newkey rsa:2048 -keyout selfsigned.key -out selfsigned.crt -days 3650 -nodes -subj "/C=GB/ST=London/L=London/O=Google Trust Services LLC/CN=www.google.com"

openssl req -x509 -nodes selfsigned.key -out selfsigned.crt -subj "/C=GB/ST=London/L=London/O=Google Trust Services LLC/CN=www.google.com"

certbot --nginx --register-unsafely-without-email -d $DOMAIN --non-interactive --agree-tos  --https-port 444 --no-redirect
sed -i "s/listen 444 ssl;/listen 444 ssl http2;/" web.conf
echo "https://$DOMAIN/$USER_SECRET/">use-link

systemctl restart nginx
