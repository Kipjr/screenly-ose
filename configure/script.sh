#!/bin/bash

ENABLE_SSL=false
SYSTEM_UPGRADE=false
MANAGE_NETWORK=false

usage () { echo "How to use"; }

options='su:i:j:r:R:v:h'
while getopts $options option
do
    case "$option" in
        i  ) i_func;;
        j  ) j_arg=$OPTARG;;
        r  ) rflag=true; small_r=true;;
        R  ) rflag=true; big_r=true;;
        s  ) ENABLE_SSL=true;;
        u  ) SYSTEM_UPGRADE=true;;
        n  ) MANAGE_NETWORK=true;;
        h  ) usage; exit;;
        \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
    esac
done

if ((OPTIND == 1))
then
    echo "No options specified"
fi

shift $((OPTIND - 1))

if (($# == 0))
then
    echo "No positional arguments specified"
fi

if ! $rflag && [[ -d $1 ]]
then
    echo "-r or -R must be included when a directory is specified" >&2
    exit 1
fi





###
### VARS
###

######
###### Static Vars
###### 

resin_wifi_connect_version="4.2.13"

######
###### Dynamic Vars
###### 

ID=$(cat /etc/os-release | grep ID | cut -d= -f2-)
ID_LIK=$(cat /etc/os-release | grep ID_LIKE | cut -d= -f2-)
VERSION_ID=$(cat /etc/os-release | grep VERSION_ID | cut -d= -f2-)
VERSION_CODENAME=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d= -f2-)
MACHINE=$(uname -m)
ASSETS="/home/pi/screenly_assets"
SCREENLY_CONFIG="/home/pi/.Screenly"
SCREENLY_INSTALLED=[[ -d $ASSETS ]] && [[ -d $SCREENLY_CONFIG ]]
screenlyd=docker image ls | grep screenly


###
### FUNCTIONS
###

regex_replace_infile () {
 #
 # path_file find replace comment
 #
  cat $1 | perl -pe "s/$2/$3/" > /tmp/regex.tmp
  mv /tmp/regex.tmp  $1
  if [[ ! -z $4 ]];then 
    echo $4
  fi
  echo -e "\tReplace '$2' with '$3' in $1"
}

copy_file2 () {
 # source target owner group flags comment
 #
 #
  str=""
  if [ ! -z $6 ]; then
    echo $6
  fi
  str+="Copying $1 to $2"
  if [ ! -z $1 ] && [ ! -z $2 ]; then
    #make this -n -f optional based on args
    cp -n $1 $2 -f 
    if [ ! -z $3 ] && [ ! -z $4 ];then 
      chown $3:$4 $2
      str+=" as $3:$4"
    fi
    if [ ! -z $5 ];then 
      chmod $5 $2
      str+=" with $5 flags"
    fi
    echo -e "\t$str"
  else 
    echo "Not enough arguments"
  fi
}

copy_file () {
 # source target owner group flags comment
 #
 #
  options=':s:t:o:gf:m:c:h'
  while getopts $options option
  do
      case "$option" in
          s  ) SOURCE=$OPTARG;;
          t  ) TARGET=$OPTARG;;
          o  ) OWNER=$OPTARG;;
          g  ) GROUP=$OPTARG;;
          f  ) FORCE=true;;
          m  ) FLAGS=$OPTARG;;
          c  ) COMMENT=$OPTARG;;
          h  ) usage; exit;;
          \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
          :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
          *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
      esac
  done

  if ((OPTIND == 1))
  then
      echo "No options specified"
  fi

  shift $((OPTIND - 1))

  if (($# == 0))
  then
      echo "No positional arguments specified"
  fi

  if ![[ $SOURCE && [[ -d $1 ]] ]] || ![[ $TARGET && [[ -d $1 ]] ]]
  then
      echo "-s and -t must be included" >&2
      exit 1
  fi
  if ![[ $OWNER && [[ -d $1 ]] ]] || ![[ $GROUP && [[ -d $1 ]] ]]
  then
      echo "-o and -g must be included" >&2
      exit 1
  fi

  str=""

  if [[ $COMMENT && [[ -d $1 ]] ]]
  then
      echo "$COMMENT"
  fi

  str+="Copying $SOURCE to $TARGET"
  
  if [[ -z $FORCE]]; then
    cp -n $SOURCE $TARGET -f
  else 
    cp -n $SOURCE $TARGET
  fi 
  if [ ! -z $3 ] && [ ! -z $4 ];then 
    chown $GROUP:$OWNER $TARGET
    str+=" as $GROUP:$OWNER"
  fi
  if [ ! -z $FLAGS ];then 
    chmod $FLAGS $TARGET
    str+=" with $FLAGS flags"
  fi
  echo -e "\t$str"
}


######
######  Roles
######  
  
  
  
###  system
    
    
  
#- name: test for available disk space
#  assert:
#    that:
#     - "{{ item.size_available > 500 * 1000 * 1000 }}" # 500Mb
#  when: "{{ item.mount == '/' }}"
#  with_items: "{{ ansible_mounts }}"


# We need custom handling for BerryBoot as it lacks `/boot`.
# To detect this, the image creates `/etc/berryboot`.
DIR="/etc/berryboot"
if [ -d "$DIR" ]; then
  ### Take action if $DIR exists ###
  echo "Detected BerryBoot installation. Skipping some steps."
  
else
  ###  Control will jump here if $DIR does NOT exists ###
  echo "Not BerryBoot. Can continue.\nBacking up /boot/config.txt"
  cp /boot/config.txt /boot/config.txt.bak
  regex_replace_infile /boot/config.txt ^framebuffer_depth=[0-9]+$ framebuffer_depth=32 'Make sure we have proper framebuffer depth'
  regex_replace_infile /boot/config.txt ^framebuffer_ignore_alpha=[0-9]+$ framebuffer_ignore_alpha=1 'Fix framebuffer bug'
  echo "Backup kernel boot args"
  cp -n /boot/cmdline.txt /boot/cmdline.txt.orig
  regex_replace_infile /boot/cmdline.txt '(^(?!$)((?!splash).)*$)' '\1 splash' 'For splash screen using Plymouth'
  regex_replace_infile /boot/cmdline.txt  '(^(?!$)((?!vt.global_cursor_default=0).)*$)' '\1 vt.global_cursor_default=0' 'Remove blinking cursor'
  regex_replace_infile /boot/cmdline.txt  '(^(?!$)((?!quiet init=/lib/systemd/systemd).)*$)' '\1 quiet init=/lib/systemd/systemd' 'Use Systemd as init and quiet boot process'
  regex_replace_infile /boot/cmdline.txt  '(^(?!$)((?!net\.ifnames=0).)*$)' '\1 net.ifnames=0' 'ethN/wlanN names for interfaces'
  
fi


# Sometimes in some packages there are no necessary files.
# They are required to install pip dependencies.
# In this case we need to reinstall the packages.
FILE="/usr/include/arm-linux-gnueabihf/sys/cdefs.h"
if [ -d "$FILE" ]; then
  echo "cdefs.h exist"
else
  echo "cdefs.h not found."
  sudo apt-get remove libc6-dev
  sudo apt-get update && sudo apt get install libc6-dev -y
fi

DIR=" /usr/lib/gcc/arm-linux-gnueabihf/4.9/cc1plus"
if [ -d "$DIR" ]; then
  echo "cc1plus exists"
else
  echo "cc1plus not found."
  sudo apt-get remove build-essential
  sudo apt-get update && sudo apt get install build-essential -y
fi


apt-get install -y \
  console-data \
  libffi-dev \
  libssl-dev \
  matchbox \
  omxplayer \
  python-dev \
  python-gobject \
  python-netifaces \
  python-simplejson \
  redis-server \
  rpi-update \
  sqlite3 \
  systemd \
  uzbl \ 
  x11-xserver-utils \
  xserver-xorg \


apt-get purge -y 
	visor \
	lightdm \
	lightdm-gtk-greeter \
	dphys-swapfile \
	rabbitmq-server
  pix-plym-splash \
	cups \
	cups-browsed \
	cups-client \
	cups-common \
	cups-daemon \
	cups-server-common

apt-get autoremove -y
apt-get dist-upgrade -y

echo "Remove deprecated pip dependencies"

copy_file "rc.local"  "/etc/rc.local" root root 0755 "Copy in rc.local"
copy_file "01_nodoc"  "/etc/dpkg/dpkg.cfg.d/01_nodoc" root root 0644 "Copy in 01_nodoc"
copy_file "10-evdev.conf"  "/usr/share/X11/xorg.conf.d/10-evdev.conf" root root 0644 "Copy in evdev"
copy_file "10-serverflags.conf"  "/usr/share/X11/xorg.conf.d/10-serverflags.conf" root root 0644 "Disable DPMS"

echo "Clear out X11 configs (disables touchpad and other unnecessary things)"
X11_configs=('50-synaptics.conf' '10-quirks.conf' '50-wacom.conf')
for c in "${X11_configs[@]}"
do
  sudo rm "/usr/share/X11/xorg.conf.d/$c"
done

echo "Disable swap"
sudo /sbin/swapoff --all removes=/var/swap
sudo rm /var/swap -r 
    
    
    
###  rpi-update
    
    
if [[-z $SYSTEM_UPGRADE ]]; then

  if [[VERSION_CODENAME=="wheezy"]]; then 
    echo "download rpi-update"
    sudo curl -L --output /usr/bin/rpi-update https://raw.githubusercontent.com/Hexxeh/rpi-update/master/rpi-update && sudo chmod +x /usr/bin/rpi-update
    echo "Run kernel upgrade (this can take up to 10 minutes)"  
    sudo SKIP_KERNEL=1 rpi-update
  fi
fi
    
###  screenly

echo "Ensure folders exist"
DIRS=('.screenly' '.config' '.config/uzbl')
for d in "${DIRS[@]}"
do
  fd="/home/pi/$d"
  if [[ ! -d $fd ]]; then
    mkdir $fd
    sudo chown pi:pi $fd
  fi 
done    
    
#do not force
copy_file "screenly.conf"  "/home/pi/.screenly/screenly.conf" pi pi 0600 "Copy Screenly default config"



copy_file "default_assets.yml"  "/home/pi/.screenly/default_assets.yml" pi pi 0600 "Copy Screenly default assets file"
regex_replace_infile /home/pi/.screenly/screenly.conf '^.*listen.*' '' 'Remove deprecated parameter "listen"'
copy_file "gtkrc-2.0"  " /home/pi/.gtkrc-2.0" pi pi 0600 "Copy in GTK config"
copy_file "uzbl-config"  "/home/pi/.config/uzbl/config-screenly" pi pi 0600 "Copy in UZBL config"

echo "Install pip dependencies"
pip install --requirement /home/pi/screenly/requirements/requirements.txt --no-cache-dir --upgrade


#do not force
copy_file "screenly.db"  "/home/pi/.screenly/screenly.db" pi pi 0600 "Create default assets database if does not exists"

echo "Migrate database" && sudo -u pi python /home/pi/screenly/bin/migrate.py

echo "Remove screenly_utils.sh" && sudo rm /usr/local/bin/screenly_utils.sh

echo "Cleanup Cron" && sudo rm "/etc/cron.d/Cleanup screenly_assets"

echo "Download upgrade_screenly.sh from github repository"
  sudo curl -L --output /usr/local/sbin/upgrade_screenly.sh https://raw.githubusercontent.com/Screenly/screenly-ose/master/bin/install.sh && sudo chmod 0700 /usr/local/sbin/upgrade_screenly.sh


copy_file "files/screenly_overrides"  "/etc/sudoers.d/screenly_overrides" root root 0440 "Copy screenly_overrides"
copy_file "files/screenly_usb_assets.sh"  "/usr/local/bin/screenly_usb_assets.sh" root root 0755 "Copy screenly_usb_assets.sh"
copy_file "50-autoplay.rules"  "/etc/udev/rules.d/50-autoplay.rules" root root 0644 "Installs autoplay udev rule"
copy_file "/lib/systemd/system/systemd-udevd.service"  "/etc/systemd/system/systemd-udevd.service" root root 0740 "Copy systemd-udevd service"

regex_replace_infile /etc/systemd/system/systemd-udevd.service '^MountFlags=.+$' 'MountFlags=shared' 'Configure systemd-udevd service'


echo "Copy screenly systemd units"
system_d_units=('X.service' 'matchbox.service' 'screenly-celery.service' 'screenly-viewer.service' 'screenly-web.service' 'screenly-websocket_server_layer.service' 'udev-restart.service')
for sdu in "${system_d_units[@]}"
do
  sudo cp "./files/$sdu" "/etc/systemd/system/$sdu"
done

copy_file "plymouth-quit-wait.service"  "/lib/systemd/system/plymouth-quit-wait.service" root root 0644 "Copy plymouth-quit-wait.service"
copy_file "plymouth-quit.service"  "/lib/systemd/system/plymouth-quit.service" root root 0644 "Copy plymouth-quit.service"

echo "Enable Screenly systemd services"
for sdu in "${system_d_units[@]}"
do
  sudo systemctl enable $sdu chdir=/etc/systemd/system
done


    
###  network
    
echo "Check if screenly-network-manager files exist"    
FILE="/usr/sbin/screenly_net_mgr.py"
if [ -d "$FILE" ]; then
  ### Take action if $FILE exists ###
	echo "Detected screenly-network-manager files."
	systemctl disable screenly-net-manager.service
	systemctl disable screenly-net-watchdog.timer
else    
fi

echo "Remove Network manager and watchdog"
screenly_net_service_files=('screenly_net_mgr.py' 'screenly_net_watchdog.py')
for snsf in "${screenly_net_service_files[@]}"
do 
  sudo rm "/usr/sbin/$snsf"
done

echo "Remove network manager and watchdog unit files"
screenly_net_services=('screenly-net-manager.service' 'screenly-net-watchdog.service')
for sns in "${screenly_net_services[@]}"
do 
  sudo rm "/etc/systemd/system/$sns"
done

echo "Remove network watchdog timer file" && sudo rm /etc/systemd/system/screenly-net-watchdog.timer

# Use resin-wifi-connect if Stretch


if [[ $MANAGE_NETWORK==true ]];then
  regex_replace_infile /var/lib/polkit-1/localauthority/10-vendor.d/org.freedesktop.NetworkManager.pkla '^Identity=.*' 'Identity=unix-group:netdev;unix-group:sudo:pi' 'Add pi user to Identity'
  regex_replace_infile /var/lib/polkit-1/localauthority/10-vendor.d/org.freedesktop.NetworkManager.pkla '^ResultAny=.*' 'ResultAny=yes' 'Set ResultAny to yes'
  echo "Copy org.freedesktop.NetworkManager.pkla to 50-local.d"
  cp -f /var/lib/polkit-1/localauthority/10-vendor.d/org.freedesktop.NetworkManager.pkla /etc/polkit-1/localauthority/50-local.d
  echo "Disable dhcpcd"
  systemctl disable dhcpcd
  echo "Activate NetworkManager"
  systemctl enable NetworkManager

fi





if [[ $MANAGE_NETWORK=="True" ]]; then
   if [[ ! -f "/usr/local/share/wifi-connect/ui/$resin_wifi_connect_version" ]]; then
      if [[ $ansible_distribution_major_version>=9 ]]; then
      echo "Download resin-wifi-connect release"
      sudo curl -L --output /home/pi/resin-wifi-connect.tar "https://github.com/resin-io/resin-wifi-connect/releases/download/v$resin_wifi_connect_version/wifi-connect-v$resin_wifi_connect_version-linux-rpi.tar.gz"
 

#not finished
if [[-z $MANAGE_NETWORK=="true" ]]; then
  if [[ ! -z $resin_wifi_version_file_exist ]]; then
    if [[ $ansible_distribution_major_version>=9 ]]; then
      sudo tar -xfv /home/pi/resin-wifi-connect.tar.gz /home/pi && chown pi:pi /home/pi/resin-wifi-connect -R
      copy_file "/home/pi/ui/"  "/usr/local/share/wifi-connect/ui" pi pi 0755 "Copy 'ui' folder"
      copy_file "/home/pi/wifi-connect"  "/usr/local/sbin" pi pi 0755 "Copy wifi-connect file"
      echo "Touch resin-wifi-connect version file" &&  touch "/usr/local/share/wifi-connect/ui/$resin_wifi_connect_version"
      echo "Remove unarchive files"
      sudo rm "/home/pi/wifi-connect" -r 
      sudo rm "/home/pi/ui" -r 
      sudo rm "/home/pi/resin-wifi-connect.tar.gz" -r 
    fi
  fi
fi

copy_file "wifi-connect.service"  "/etc/systemd/system/wifi-connect.service" root root 0644 "Copy wifi-connect systemd unit"
echo "Enable wifi-connect systemd service" && systemctl enable wifi-connect.service
echo "Touch initialized file" && touch "/home/pi/.screenly/initialized"




###  splashscreen
    
if [[VERSION_CODENAME=="jessie"]]; then 
# If Jessie
  if [[ $ansible_distribution_major_version<=7 ]]; then
    sudo apt install -y fbi
    copy_file "splashscreen.png"  "/etc/splashscreen.png" root root 0644 "Copies in splash screen"
    copy_file "asplashscreen"  " /etc/init.d/asplashscreen" root root 0755 "Copies in rc script"
    echo "Enables asplashscreen"
    if [[ !-d "/etc/rcS.d/S01asplashscreen" ]]; then
      update-rc.d asplashscreen defaults
    fi
  fi
  
else 
# If not Jessie
  if [[ $ansible_distribution_major_version>7 ]]; then
    echo "Remove older versions"
    sudo rm -f /etc/splashscreen.jpg
    sudo rm -f /etc/init.d/asplashscreen
    echo "Disable asplashscreen" && sudo update-rc.d asplashscreen remove
    echo "Installs dependencies (not Jessie)" && sudo apt install -y plymouth pix-plym-splash
    echo "Copies plymouth theme"
    paymouth_files=('screenly.plymouth' 'screenly.script' 'splashscreen.png')
    for pf in "${paymouth_files[@]}"
    do
      sudo cp "./files/$pf" " /usr/share/plymouth/themes/screenly/$pf"
    done
    echo "Set splashscreen" && plymouth-set-default-theme -R screenly
    echo  "Set plymouthd.default"
    sudo cp "./files/plymouthd.default"  "/usr/share/plymouth/plymouthd.default"
  fi
fi


    
###  nginx
    

# Enable Nginx
echo "Install nginx-light"
sudo apt-get install nginx-light -y
echo "Cleans up default config"
sudo rm /etc/nginx/sites-enabled/default
copy_file "nginx.conf"  "/etc/nginx/sites-enabled/screenly.conf" root root 0644 "Installs nginx config"
regex_replace_infile "/etc/systemd/system/screenly-web.service"  '^.*LISTEN.*' '' 'Modifies screenly-web service to only listen on localhost'
  
    
###  ssl
if [[ -z $ENABLE_SSL ]]; then
  use_ssl=$(cat /home/pi/.screenly/screenly.conf | grep use_ssl | cut -d= -f2)
  if [[ -z $use_ssl ]] || [[ $use_ssl=='False' ]]; then
    echo "Install nginx-light"
    sudo apt-get install nginx-light -y
    echo "Cleans up default config"
    sudo rm /etc/nginx/sites-enabled/default  
    copy_file "nginx.conf"  "/etc/nginx/sites-enabled/screenly.conf" root root 0644 "Installs nginx config"
    service nginx restart
    copy_file "files/screenly.crt"  "/etc/ssl/screenly.crt" root root 0600 "Installs self-signed certificates / crt"
    copy_file "files/screenly.key"  "/etc/ssl/screenly.key" root root 0600 "Installs self-signed certificates / key"
    regex_replace_infile "/home/pi/.screenly/screenly.conf" '^.*use_ssl.*' 'use_ssl = True' 'Turns on the ssl mode'
    regex_replace_infile "/etc/systemd/system/screenly-web.service"  '^.*LISTEN.*' '' 'Modifies screenly-web service to only listen on localhost'
    sudo systemctl daemon-reload
    systemctl restart screenly-websocket_server_layer.service
    systemctl restart screenly-web.service
  fi
fi    
###  tools
copy_file "files/ngrok"  "/usr/local/bin/" root root 0755 "Copy ngrok binary"
copy_file "files/nginx.conf"  "/etc/nginx/sites-enabled/screenly_assets.conf" root root 0644 "Installs nginx config"
