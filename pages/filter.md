---
title: فیلترینگ چگونه کار میکند
nav: مقابله با فیلترینگ
nav_order: 3
---

فیلترچی مراحل زیر را برای فیلترینگ انجام میدهد
- چک کردن درخواست DNS (نحوه مقابله)
- چک کردن تک تک بسته های TCP برای بررسی SNI (نحوه مقابله)
- چک کردن IP جهت بلاک کردن (نحوه مقابله)
- اضافه کردن آی پی های مشکوک به لیست زرد جهت فیلتر کردن (نحوه مقابله)

## نحوه مقابله با چک کردن درخواست DNS
تنها راهکار کارآمد برای این موضوع DNS over HTTPS یا به اختصار DoH هست

که تقریبا تمام سرویس دهنده ها فیلتر شدن

راهکار اگر یه سرور خارج از کشور دارید به راحتی میتونید DoH را تعریف کنید

آموزش اضافه کردن DoH برای nginx

کافی است بخش زیر را به لیست اضافه کنید
```
location /path {
    proxy_pass https://dns.google:443/;
}
 ```
پس از آن می توانید در گوگل یا اپلیکیشن فیلترشکن خود از این DNS ها استفاده کنید.

```
https://your-domain.com/path/dns-query{?dns}
```

توجه داشته باشید هرگز بدون path از این روش استفاده نکنید چون قابل شناسایی هست اما اگر path داشته باشد چون فیلترچی فقط SNI را می بینه هیچ نگرانی وجود ندارد.

## مقابله با چک کردن SNI 
این روش در خیلی از موارد جواب میدهد یعنی شما هیچ نیازی به سرور ثالث ندارید.
تنها حالتی که جواب نمیدهد اینه که آی پی کامل بلاک  باشه مثل فیلتر بودن آی پی های تلگرام

داستان چیه؟

موضوع اینه که فیلترچی نمیتونه خیلی راحت پکت های TCP را به هم بچسبونه برای اینکه بررسی کنه
پس کارش اینه که یک بسته TCP را منحصرا نگاه میکنه

خوب اگر ما بسته TCP که توش SNI ارسال میشه را بشکنیم دیگه فیلترچی نمیتونه فیلتر کنه

به همین راحتی به همین خوشمزگی بدون سرور بدون کم شدن سرعت

خوب یه سری کارهای خوب شده که در زیر لیست شده اند
فقط یادتون نره برای کارایی اینا حتما باید از DoH استفاده کنید که در بالا گفتم

- [Good By DPI](https://github.com/ValdikSS/GoodbyeDPI)
- [Green Tunnel](https://github.com/SadeghHayeri/GreenTunnel)
- [DPI Tunnel Android](https://github.com/zhenyolka/DPITunnel-android)


## رفع فیلتر آی پی های بلاک شده

برای مثال کل رنج آی پی های تلگرام فیلتر شده
برای حل این مشکل نیاز داریم که از یه سرور واسط استفاده کنیم

خوب من یه راه حل بهینه را میگم و دیگه به بقیه راه ها تو اینجا نمیپردازم


خوب کافیه یه فیلترشکن HTTPS با FakeSNI درست کنیم

 برای اینکار از [gost](https://github.com/ginuerzh/gost/blob/master/README_en.md) استفاده میکنیم

سمت سرور
```
gost -L=http+tls://user:pass@:443
```

ما ابتدا درخواست های DNS را بررسی میکنیم
اگر سایت فیلتر شده بود از فیلترشکن ردش میکنیم
اگه نبود از حالت عادی استفاده میکنه

به همین راحتی به همین خوش مزگی

حالا ما از کلاینت CLASH استفاده میکنیم که فوق العاده هست

- [Android](https://github.com/Kr328/ClashForAndroid)
- [Windows](https://github.com/Fndroid/clash_for_windows_pkg/releases/download/0.20.4/Clash.for.Windows.Setup.0.20.4.exe)
- [macOS](https://github.com/Fndroid/clash_for_windows_pkg/releases/download/0.20.4/Clash.for.Windows-0.20.4.dmg) اسمش کلش فور ویندوزه ولی برای مک هم هست
- [macOS M1](https://github.com/Fndroid/clash_for_windows_pkg/releases/download/0.20.4/Clash.for.Windows-0.20.4-arm64.dmg)  اسمش کلش فور ویندوزه ولی برای مک هم هست
- [iOS](https://apps.apple.com/app/stash/id1596063349?platform=iphone)

متن زیر را کپی کنید و تنظیمات لازم را انجام دهید و در فایلی ذخیره کنید و در کلاینت کلش قرار دهید

موارد زیر را در کانفیگ زیر تغییر دهید
your-domain.com
user
pass

```
mixed-port: 7890
allow-lan: false
log-level: info
secret: ""
external-controller: 127.0.0.1:9090
ipv6: false
mode: rule
proxies:
  - name: Proxy
    type: http
    server: your-domain.com
    port: "443"
    tls: true
    skip-cert-verify: true
    sni: mail.google.com  
    username: user
    password: pass
rule-providers:
  iran:
    type: http
    behavior: classical
    url: "https://antyfilter.github.io/AntyProxy/clash/iran.yml"
    path: ./ruleset/iran.yaml
    interval: 432000
rules:
  - RULE-SET,iran,DIRECT
  - DOMAIN,www.googleapis.com,DIRECT
  - DST-PORT,80,Proxy
  - DST-PORT,443,Proxy
  - MATCH,DIRECT
dns:
  enable: true
  listen: 0.0.0.0:53
  default-nameserver:
    - 8.8.8.8
  enhanced-mode: fake-ip
  fake-ip-range: 10.10.0.0/16
  fake-ip-filter:
     - '*.ir'
  nameserver:
    - https://your-domain.com/path/dns-query
    - tls://dns.rubyfish.cn:853
    - 8.8.8.8
  fallback:
    - tcp://1.1.1.1
    - tls://dns.rubyfish.cn:853
    - 8.8.8.8
  fallback-filter:
    ipcidr:
      - 10.0.0.0/8
```


## مقابله با قرارگرفتن در لیست زرد جهت بررسی و بالا رفتن احتمال فیلتر شدن

هر پروتکلی جز HTTPS خطر فیلترینگ داره
خوب فیلترچی مشکوک میشه که چیه که اینقدر آدم دارن ازش استفاده میکنند
ولی مثلا اگه سایت گوگل باشه رو که نمیتونه فیلتر کنه و ترافیکش هم بالاست

خوب پس از HTTPS استفاده کنید و FakeSNI سایت های مشهور استفاده کنید.

روزتون خوش
