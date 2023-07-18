<br>
<div align="center">
 <img src="https://github.com/trinity-labs/trinity-skin/assets/45216746/f8b4b03a-1371-4abb-bf4a-fd9e2a1c7446" width="30%">
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

✅ Lighttpd Ready - Remove Mini_httpd 

[ACF on Lighttpd](https://gitlab.alpinelinux.org/trinity-labs/mini_httpd-lighttpd)

- <ins>**Features**</ins>

Light-weight App (Less than 2 MB) installed

<div align="left">
 <hr>
 
> <ins>**ACF System Version - ASV**</ins>

 <hr>
<img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/dae56d30-7c39-433c-9138-c429f3e862f0">

Fisrt check `Alpine Linux` running version<br>
Then compare to Alpine official [Releases](https://www.alpinelinux.org/releases/#content) website<br>
And build latest version post url from Alpine official website eg :<br>
<img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/e0318739-c4e4-4119-83cd-88931bd188eb">
<br>
So we have a basic version checker in `Lua` that need `WAN` access and `DNS` avaible
 <hr>

> <ins>**ACF System Self-check - ASS**</ins>

 <hr>
 <img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/5c9ecb8a-aca9-4b70-a5ea-3c2b063759c9">
<br>
<br>

Return `Lua` ACF used version and `ACF Server` version. <br>
<br>
⚠️ `Served by` field, check version of both `lighttpd` and `mini_httpd`. If `lighttpd` is install on system, command return `lighttpd` as prefered ACF server. However, it's the best choice to switch to `lighttpd` for `ACF`


 <hr>

 > <ins>**ACF System Uptime - ASU**</ins>

 <hr>
 <img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/1a34c041-7a82-4977-a5ce-3bacd0cd67c8">

Get **live** uptime timer in `Lua` and `JS` to parse `/proc/uptime` in major Linux distro to convert seconds in human readeable value and up to centuries
 <hr>

> <ins>**ACF CPU Manufacturer - ACM**</ins>

 <hr>
 <img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/9b81be2f-d91f-416b-9683-784d490887e5">

Return `CPU Model` and `Manufacturer` icon. If now, return `board` and `bios` infos - (please report errors)
 <hr>
 
> <ins>**ACF CPU Temp - ACT**</ins>

 <hr>
 <img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/1074ce4e-e48d-4dd6-8654-4b0cca264536">
<br>
<br>

 Get **live** proc temp (checked every seconds) from `/sys/class/thermal/thermal_zone2/temp` (seems target `x86_pkg_temp` on main x86 systems - please report errors)
else print `NaN`

And many other - Project in constent dev
 </div>

- <ins>**Install**</ins>

Install essential packages :

```bash
 $: apk add curl util-linux lspci
```

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