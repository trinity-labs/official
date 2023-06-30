<br>
<div align="center">
 <img src="https://github.com/trinity-labs/trinity-skin/assets/45216746/f8b4b03a-1371-4abb-bf4a-fd9e2a1c7446" width="30%">
</div>

<br>
<hr/>

  ![](https://img.shields.io/github/stars/trinity-labs/trinity-skin.svg)
  ![Views](https://img.shields.io/endpoint?url=https%3A%2F%2Fhits.dwyl.com%2Ftrinity-labs%2Ftrinity-skin.json%3Fcolor%3Dpurple)
  ![contributions welcome](https://img.shields.io/badge/contributions-welcome-ff69b4.svg?style=flat)
  ![](https://img.shields.io/github/issues/trinity-labs/trinity-skin.svg)
 
<br>

**From a Skin to an App for Linux `Alpine Configuration Framework` commonly called [ACF](https://wiki.alpinelinux.org/wiki/Alpine_Configuration_Framework_Design)**
<br>

✅ Lighttpd Ready - Remove Mini_httpd 

[ACF on Lighttpd](https://gitlab.alpinelinux.org/trinity-labs/mini_httpd-lighttpd)

> ⚠️ **CPU Temp bugs - Network Chart only eth0 - Disk Partition to be continued, etc:** Please be patient!

Light-weight App (Less than 2 MB) installed

> ⚠️ `Serve by` field check version of both `lighttpd` and `mini_httpd`. If `lighttpd` is install on system, command return `lighttpd` as prefered ACF server. However, it's the best choice to switch to `lighttpd` for `ACF`

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

- **Logon**

<img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/bf78f68a-d45f-492c-b348-3b00cf3c5b4b">
<br>
<br>

- **Dashboard**

<img src="https://github.com/trinity-labs/dashboard-skin/assets/45216746/9e465dad-57b6-4cf7-b9eb-3d9b1c25fb0c">