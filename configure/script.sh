#!/bin/bash

# read the options
TEMP=`getopt -o f:s::d:a::  "$@"`
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -f)
            a=$2 ; shift 2 ;;
        -s)
            b='.' ; shift 2 ;;
        -d)
            c=$2 ; shift 2;;
        -a)
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

# Now take action
echo "$action file $fileName from $sourceDir to $destinationDir"

###
### VARS
###

skip-tags 
enable-ssl
system-upgrade


os=cat /etc/os-release
NAME="Ubuntu"
ID=ubuntu
ID_LIKE=debian
VERSION_ID="16.04"
VERSION_CODENAME=xenial
UBUNTU_CODENAME=xenial




sa="/home/pi/screenly_assets"
sc="/home/pi/.Screenly"
screenly=[[ -d $sc ]] && [[ -d $sa ]]
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

copy_file () {
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

https://wiki.bash-hackers.org/howto/getopts_tutorial
copy_file2 () {
 # source target owner group flags comment
 #
 #
  while getopts ":s:t:o:g:p:c:f:" opt; do
    case $opt in
      s) 
        source="$OPTARG"
        echo "-s was triggered!" >&2
        ;;
      t) 
        target="$OPTARG"
        echo "-t was triggered!" >&2
        ;;
      o) 
        owner="$OPTARG"
        echo "-o was triggered!" >&2
        ;;
      g) 
        group="$OPTARG"
        echo "-g was triggered!" >&2
        ;;
      p) 
        flags="$OPTARG"
        echo "-p was triggered!" >&2
        ;;
      c) 
        comment="$OPTARG"
        echo "-c was triggered!" >&2
        ;;
      f) 
        force="$OPTARG"
        echo "-f was triggered!" >&2
        ;;
      \?) 
        echo "Invalid option -$OPTARG" >&2 
        ;;
      :)
       echo "Option -$OPTARG requires an argument." >&2
       ;;
    esac
    printf "Argument is %s\n" "$comment"
  done
 
}





service_restart () {
 # service comment 
 #
 #
  while getopts ":s:c:" opt; do
    case $opt in
      s) 
        service="$OPTARG"
        ;;
      c) 
        comment="$OPTARG"
        ;;
      \?) 
        echo "Invalid option -$OPTARG" >&2 
        ;;
      *)
       echo "Option -$OPTARG requires an argument." >&2
       ;;
    esac
	if [[ -z $service ]]; then
	    systemctl restart $service 
	    if [[ -z $comment ]]; then
    		echo "$comment"
		fi
	fi
  done
 
}





DIR="/etc/httpd/"
if [ -d "$DIR" ]; then
  ### Take action if $DIR exists ###
  echo "Installing config files in ${DIR}..."
else
  ###  Control will jump here if $DIR does NOT exists ###
  echo "Error: ${DIR} not found. Can not continue."
  exit 1
fi



#!/bin/bash
dldir="$HOME/linux/5.x"
_out="/tmp/out.$$"
 
# Build urls
url="some_url/file.tar.gz"
file="${url##*/}"
 
### Check for dir, if not found create it using the mkdir ##
[ ! -d "$dldir" ] && mkdir -p "$dldir"



FILE=/etc/resolv.conf
if [ -f "$FILE" ]; then
    echo "$FILE exists."
fi


- name: Install Screenly
  hosts: all
  user: pi
  become: yes
  vars:
    manage_network: "{{ lookup('env', 'MANAGE_NETWORK') }}"

  handlers:
    - name: restart-nginx
      service:
        name: nginx
        state: restarted

    - name: reload systemctl
      command: systemctl daemon-reload

    - name: restart-screenly-websocket_server_layer
      command: systemctl restart screenly-websocket_server_layer.service

    - name: restart-screenly-server
      command: systemctl restart screenly-web.service

    - name: restart-x-server
      command: "systemctl restart {{ item }}"
      with_items:
	X.service
	matchbox.service

    - name: restart-screenly-viewer
      command: systemctl restart screenly-viewer.service

  roles:
  
  
  
  
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
    
    
if [[-z system-upgrade ]]; then

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


if [[ $manage_network==true ]];then
  regex_replace_infile /var/lib/polkit-1/localauthority/10-vendor.d/org.freedesktop.NetworkManager.pkla '^Identity=.*' 'Identity=unix-group:netdev;unix-group:sudo:pi' 'Add pi user to Identity'
  regex_replace_infile /var/lib/polkit-1/localauthority/10-vendor.d/org.freedesktop.NetworkManager.pkla '^ResultAny=.*' 'ResultAny=yes' 'Set ResultAny to yes'
  echo "Copy org.freedesktop.NetworkManager.pkla to 50-local.d"
  cp -f /var/lib/polkit-1/localauthority/10-vendor.d/org.freedesktop.NetworkManager.pkla /etc/polkit-1/localauthority/50-local.d
  echo "Disable dhcpcd"
  systemctl disable dhcpcd
  echo "Activate NetworkManager"
  systemctl enable NetworkManager

fi







- name: Check if resin-wifi-connect required version exist
  stat:
    path: "/usr/local/share/wifi-connect/ui/{{ resin_wifi_connect_version }}"
  register: resin_wifi_version_file
  when:
    - ansible_distribution_major_version|int >= 9

- set_fact: resin_wifi_version_file_exist="{{resin_wifi_version_file.stat.exists}}"
  when:
    - ansible_distribution_major_version|int >= 9

- name: Download resin-wifi-connect release
  get_url:
    url: "https://github.com/resin-io/resin-wifi-connect/releases/download/v{{ resin_wifi_connect_version }}/wifi-connect-v{{ resin_wifi_connect_version }}-linux-rpi.tar.gz"
    dest: /home/pi/resin-wifi-connect.tar.gz
  when:
    - ansible_distribution_major_version|int >= 9
    - not resin_wifi_version_file_exist
    - manage_network|bool == true

#not finished
if [[-z $manage_network=="true" ]]; then
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
  if [[ $ansible_distribution_major_version> ]]; then
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
    
    
    ---
# Enable Nginx
- name: Check screenly.conf
  command: cat /home/pi/.screenly/screenly.conf
  register: config

- set_fact: no_ssl="{{config.stdout.find('use_ssl = True') == -1}}"

- name: Installs Nginx
  apt:
    name: nginx-light
    state: present
    update_cache: yes

- name: Cleans up default config
  file:
    path: /etc/nginx/sites-enabled/default
    state: absent


copy_file "nginx.conf"  "/etc/nginx/sites-enabled/screenly.conf" root root 0644 "Installs nginx config"

- name: Modifies screenly-web service to only listen on localhost
  lineinfile:
    regexp: '^.*LISTEN.*'
    state: absent
    dest: /etc/systemd/system/screenly-web.service
  when: no_ssl

    
    
    
###  ssl
    
    
  ---
- name: Check screenly.conf
  command: cat /home/pi/.screenly/screenly.conf
  register: config
  tags:
    - enable-ssl

- set_fact: no_use_ssl_parameter="{{config.stdout.find('use_ssl') == -1}}"
  tags:
    - enable-ssl

- name: Installs Nginx
  apt:
    name: nginx-light
    state: present
    update_cache: yes
  tags:
    - enable-ssl

- name: Cleans up default config
  file:
    path: /etc/nginx/sites-enabled/default
    state: absent
  tags:
    - enable-ssl
    
copy_file "nginx.conf"  "/etc/nginx/sites-enabled/screenly.conf" root root 0644 "Installs nginx config"
service nginx restart


copy_file "files/screenly.crt"  "/etc/ssl/screenly.crt" root root 0600 "Installs self-signed certificates / crt"
copy_file "files/screenly.key"  "/etc/ssl/screenly.key" root root 0600 "Installs self-signed certificates / key"

- name: Turn on the ssl mode
  lineinfile:
    dest: /home/pi/.screenly/screenly.conf
    insertafter: '^.*database.*'
    regexp: '^.*database.*;'
    line: 'use_ssl = True'
  tags:
    - enable-ssl
  when: no_use_ssl_parameter

- name: Turns on the ssl mode
  replace:
    replace: 'use_ssl = True'
    regexp: '^.*use_ssl.*'
    dest: /home/pi/.screenly/screenly.conf
  tags:
    - enable-ssl
  when: not no_use_ssl_parameter

- name: Modifies screenly-web service to only listen on localhost
  lineinfile:
    regexp: '^.*LISTEN.*'
    state: absent
    dest: /etc/systemd/system/screenly-web.service
  notify:
    - reload systemctl
    - restart-screenly-websocket_server_layer
    - restart-screenly-server
  tags:
    - enable-ssl
  
    
    
###  tools
copy_file "files/ngrok"  "/usr/local/bin/" root root 0755 "Copy ngrok binary"
copy_file "files/nginx.conf"  "/etc/nginx/sites-enabled/screenly_assets.conf" root root 0644 "Installs nginx config"
