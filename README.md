<br>
<div align="center">
 <img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/ec7868c6-33b9-4a5e-a6cd-5583c959c6f4" width="30%">
</div>

<br>
<hr/>

  ![](https://img.shields.io/github/stars/trinity-labs/dashboard-skin.svg)
  ![Views](https://img.shields.io/endpoint?url=https%3A%2F%2Fhits.dwyl.com%2Ftrinity-labs%2Fdashboard-skin.json%3Fcolor%3Dpurple)
  ![contributions welcome](https://img.shields.io/badge/contributions-welcome-ff69b4.svg?style=flat)
  ![](https://img.shields.io/github/issues/trinity-labs/dashboard-skin.svg)
 
<br>

**From a Skin to an App for Linux `Alpine Configuration Framework` commonly called [ACF](https://wiki.alpinelinux.org/wiki/Alpine_Configuration_Framework_Design)**
<br>
<br>
> ⚠️ **Project in constent dev, please report errors!**

This project cover **ONLY** Alpine Linux ACF Core Modules. Just the base framework (`acf-lib` / `acf-core` / `acf-alpine-baselayout`). Other app not covered for now eg: `acf-openssl` `acf-docker` `acf-etc...` It's part of a future project, maybe...

**All other core pages should modified once all dashboard modules are in prod (finished)**

Up to date shell script setup Lua 5.4

  ```bash
#!/bin/sh

 PATH=/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/root/bin
 
# Package for Alpine ACF Lua 5.4
 apk add gcc musl-dev make pkgconfig asciidoc lua5.4 lua5.4-dev lua5.4-libs lua5.4-md5 haserl-lua5.4 git || exit 1
 
# Export config lib lua 5.4
 export PKG_CONFIG_PATH=/usr/lib/pkgconfig
 
# Clone all Lua 5.4 repos

 git clone https://github.com/trinity-labs/acf-core-lua5.4
 git clone https://github.com/trinity-labs/acf-lib-lua5.4
 git clone https://github.com/trinity-labs/lua5.4-subprocess
 git clone https://github.com/trinity-labs/dashboard-skin
 
# build Libs
 cd ~/acf-lib-lua5.4
 make install
 
# build ACF
 cd ~/acf-core-lua5.4
 make install
 
# build Lua Subprocess
 cd ~/lua5.4-subprocess 
 make clean
 make install

# Setup Dashboard 
 cp ~/dashboard-skin/acf.conf /etc/acf/
 cp -r ~/dashboard-skin /usr/share/acf/www/skins/dashboard
 rm -vf /usr/shar/acf/www/skins/acf.conf
#Done
exit
  ```



✅ Lighttpd Ready - Remove Mini_httpd 

[ACF on Lighttpd](https://gitlab.alpinelinux.org/trinity-labs/mini_httpd-lighttpd)
<br>
<br>
- <ins>**Features**</ins>

Light-weight App (Less than 2 MB) installed

<div align="left">
 <hr>
 
> <ins>**ACF System Version - ASV**</ins>

 <hr>
<img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/dae56d30-7c39-433c-9138-c429f3e862f0">

**Fisrt** check `Alpine Linux` running version<br>
**Then** compare to Alpine official [Releases](https://www.alpinelinux.org/releases/#content) website<br>
**Finaly** build latest version [post](https://www.alpinelinux.org/posts/Alpine-3.15.9-3.16.6-3.17.4-3.18.2-released.html#content) `url` from Alpine official website eg :<br>
<img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/e0318739-c4e4-4119-83cd-88931bd188eb">
<br>
So we have a basic version checker in `Lua` that need `WAN` access and `DNS` avaible
 <hr>

> <ins>**ACF System Self-check - ASS**</ins>

 <hr>
 <img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/5c9ecb8a-aca9-4b70-a5ea-3c2b063759c9">
<br>
<br>

Return `Lua` ACF used version (5.4.6) and `ACF Server` version : 
- **Lighttpd: v.1.4.71 =>** last released on May 27, 2023 - **Light, Fast & Highly customisable | [ACF on Lighttpd](https://gitlab.alpinelinux.org/trinity-labs/mini_httpd-lighttpd)** <br>
- **Mini_httpd: v.1.30 =>** last released on Oct 26, 2018 <br>
<br>

⚠️ `Lua` function, check version of both `lighttpd` and `mini_httpd`. If `lighttpd` is install on system, command return `lighttpd` as prefered ACF server.<br>
<br>

**However, it's the best choice to switch to `lighttpd` for `ACF`**


 <hr>

 > <ins>**ACF System Uptime - ASU**</ins>

 <hr>
 <img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/1a34c041-7a82-4977-a5ce-3bacd0cd67c8">

Get **live** uptime timer in `Lua` and `JS` to parse `/proc/uptime` in major Linux distro to convert seconds in human readeable value and up to centuries
 <hr>

> <ins>**ACF CPU Manufacturer - ACM**</ins>

 <hr>
 <img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/9b81be2f-d91f-416b-9683-784d490887e5">

Return `CPU Model` and `Manufacturer` icon. If know, return `board` and `bios` infos - (please report errors)
 <hr>
 
> <ins>**ACF CPU Temp - ACT**</ins>

 <hr>
 <img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/1074ce4e-e48d-4dd6-8654-4b0cca264536">
<br>
<br>

 Get **live** proc temp (checked every seconds) from `/sys/class/thermal/thermal_zone2/temp` (seems target `x86_pkg_temp` on main x86 systems - please report errors)
else print `NaN`

 <hr>
 
> <ins>**ACF [Group] [Process] - [Short-Name]**</ins>

 <hr>
 
This is the convention for **ACF Dashboard Core Modules Naming**.<br>
When a module is in prod, it's pushed here!
- **ANG (ACF Network Graph)** and **ANM (ACF Network Map)** work in progress, incoming ...
- **ADV (ACF Disk Viewer)** work in progress, incoming ...

 </div>

<br>
<br>

- <ins>**Install**</ins>

Install essential packages :

Edit [ACF](https://wiki.alpinelinux.org/wiki/Alpine_Configuration_Framework_Design#ACF_Layout) core config file `/etc/acf/acf.conf` and replace following lines for overriding core template
 
  ```bash
 ...
 # Directories where the application resides
 ...
appdir=/usr/share/acf/www/skins/dashboard/app/,/usr/share/acf/app/
libdir=/usr/share/acf/www/skins/dashboard/lib/,/usr/share/acf/lib/
wwwdir=/usr/share/acf/www/skins/dashboard/www/,/usr/share/acf/www/
staticdir=/skins/static/
skindir=/skins/,/userskins/
...
  ```
  
   ```bash
 ...
# ACF is skinnable - this specifies the active skin
#  will attempt to load skin/basename(skin).css
skin=/skins/dashboard
...
  ```
<br>
<br>

> ⚠️ **CPU Temp bugs - Network Chart only eth0 - Disk Partition to be continued, etc:** Please be patient!

<br>
<br>
 
- **Logon**

<img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/721a4ce0-37d6-4108-850b-a64e94b2bf8b">
<br>
<br>

- **Dashboard**

<img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/55bfd103-cc4f-47c7-9d84-f4f649abfada">
