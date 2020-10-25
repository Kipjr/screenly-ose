#!/bin/bash
set -abhxv

#fix lang
sudo update-locale LANG=LANG=en_US.UTF-8 LANGUAGE
sudo update-locale LC_ALL=en_US.UTF-8
sudo update-locale LANGUAGE=en_US.UTF-8

export DEBIAN_FRONTEND=noninteractive
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

ENABLE_SSL=false
SYSTEM_UPGRADE=false
MANAGE_NETWORK=false

usage () { echo "How to use"; }

options='sunh'
while getopts $options option
do
    case "$option" in
        s  ) ENABLE_SSL=true;;
        u  ) SYSTEM_UPGRADE=true;;
        n  ) MANAGE_NETWORK=true;;
        h  ) usage; exit 1;;
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




###
### VARS
###

######
###### Static Vars 
###### 

resin_wifi_connect_version="4.2.13"
SCREENLY_LOG="/home/pi/screenly_install.log"

######
###### Dynamic Vars
###### 

ID=$(cat /etc/os-release | grep ID | cut -d= -f2-)
ID_LIKE=$(cat /etc/os-release | grep ID_LIKE | cut -d= -f2-)
VERSION_ID=$(cat /etc/os-release | grep VERSION_ID | cut -d= -f2-)
VERSION_CODENAME=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d= -f2-)
MACHINE=$(uname -m)
ASSETS="/home/pi/screenly_assets"
SCREENLY_CONFIG="/home/pi/.Screenly"
if [[ -d $SCREENLY_CONFIG ]]; then
  SCREENLY_INSTALLED="true"
fi
screenlyd=$(docker images ls | grep screenly)


###
### FUNCTIONS
###

regex_replace_infile () {
 #
 # path_file find replace comment
 #
  cat "$1" | perl -pe "s/$2/$3/" > /tmp/regex.tmp
  mv /tmp/regex.tmp  "$1"
  if [[ -n $4 ]];then 
    echo "$4"
  fi
  echo -e "\tReplace '$2' with '$3' in $1"
}

copy_file2 () {
 # source target owner group flags comment
 #
 #
  str=""
  if [ -n "$6" ]; then
    echo "$6"
  fi
  str+="Copying $1 to $2"
  if [ -n "$1" ] && [ -n "$2" ]; then
    #make this -n -f optional based on args
    cp -n "$1" "$2" -f 
    if [ -n "$3" ] && [ -n "$4" ];then 
      chown "$3:$4 $2"
      str+=" as $3:$4"
    fi
    if [ -n "$5" ];then 
      chmod "$5 $2"
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
  options=':s:t:u:gf:m:c:h'
  while getopts $options option
  do
      case "$option" in
          s  ) SOURCE=$OPTARG;;
          t  ) TARGET=$OPTARG;;
          u  ) OWNER=$OPTARG;;
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

  if [[ ! $SOURCE ]] && [[ ! -d $SOURCE  ]] || [[ ! $TARGET ]] && [[ ! -d $TARGET ]]
  then
      echo "-s and -t must be included" >&2
      exit 1
  fi
  if [[ ! $OWNER ]] && [[ ! $GROUP ]] 
  then
      echo "-o and -g must be included" >&2
      exit 1
  fi

  str=""

  if [[ $COMMENT ]] && [[ -d $COMMENT ]] 
  then
      echo "$COMMENT"
  fi

  str+="Copying $SOURCE to $TARGET"
  
  if [[ -z $FORCE ]]; then
    cp -n "$SOURCE" "$TARGET" -f
  else 
    cp -n "$SOURCE" "$TARGET"
  fi 
  if [[ -n "$3" ]] && [[ -n "$4" ]];then 
    chown "$GROUP:$OWNER $TARGET"
    str+=" as $GROUP:$OWNER"
  fi
  if [[ -n "$FLAGS" ]];then 
    chmod "$FLAGS $TARGET"
    str+=" with $FLAGS flags"
  fi
  echo -e "\t$str"
}


######
######  Roles
######  
  
  
###  system
role_system () {    
      


  # We need custom handling for BerryBoot as it lacks `/boot`.
  # To detect this, the image creates `/etc/berryboot`.
  DIR="/etc/berryboot"
  if [ -d "$DIR" ]; then
    ### Take action if $DIR exists ###
    echo "Detected BerryBoot installation. Skipping some steps."
    
  else
    ###  Control will jump here if $DIR does NOT exists ###
    echo "Not BerryBoot. Can continue.
    Backing up /boot/config.txt"
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
    sudo apt-get remove libc6-dev -y #2>&1 > $SCREENLY_LOG
    sudo apt-get update -y  && sudo apt-get install libc6-dev -y #2>&1 > $SCREENLY_LOG
  fi

  DIR=" /usr/lib/gcc/arm-linux-gnueabihf/4.9/cc1plus"
  if [ -d "$DIR" ]; then
    echo "cc1plus exists"
  else
    echo "cc1plus not found."
    sudo apt-get remove build-essential -y #2>&1 > $SCREENLY_LOG
    sudo apt-get update -y  && sudo apt-get install build-essential -y #2>&1 > $SCREENLY_LOG
  fi


  apt-get install -y \
    console-data \ #gives interactive prompt!!!!
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
    xserver-xorg #2>&1 > $SCREENLY_LOG


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
    cups-server-common #2>&1 > $SCREENLY_LOG

  apt-get autoremove -y #2>&1 > $SCREENLY_LOG
  apt-get dist-upgrade -y #2>&1 > $SCREENLY_LOG

  echo "Remove deprecated pip dependencies"

  copy_file -s "rc.local"  -t "/etc/rc.local" -u root -g root -m 0755 -c "Copy in rc.local"
  copy_file -s "01_nodoc"  -t "/etc/dpkg/dpkg.cfg.d/01_nodoc" -u root -g root -m 0644 -c "Copy in 01_nodoc"
  copy_file -s "10-evdev.conf"  -t "/usr/share/X11/xorg.conf.d/10-evdev.conf" -u root -g root -m 0644 -c "Copy in evdev"
  copy_file -s "10-serverflags.conf" -t "/usr/share/X11/xorg.conf.d/10-serverflags.conf" -u root -g root -m 0644 -c "Disable DPMS"

  echo "Clear out X11 configs (disables touchpad and other unnecessary things)"
  X11_configs=('50-synaptics.conf' '10-quirks.conf' '50-wacom.conf')
  for c in "${X11_configs[@]}"
  do
    sudo rm "/usr/share/X11/xorg.conf.d/$c"
  done

  echo "Disable swap"
  sudo /sbin/swapoff --all removes=/var/swap
  sudo rm /var/swap -r 
    
}    
    
###  rpi-update
role_rpi-update () {    
      
  if [[ -z $SYSTEM_UPGRADE ]]; then

    if [[ $VERSION_CODENAME == "wheezy" ]]; then 
      echo "download rpi-update"
      sudo curl -L --output /usr/bin/rpi-update https://raw.githubusercontent.com/Hexxeh/rpi-update/master/rpi-update && sudo chmod +x /usr/bin/rpi-update
      echo "Run kernel upgrade (this can take up to 10 minutes)"  
      sudo SKIP_KERNEL=1 rpi-update
    fi
  fi
}    

###  screenly
role_screenly () {
  echo "Ensure folders exist"
  DIRS=('.screenly' '.config' '.config/uzbl')
  for d in "${DIRS[@]}"
  do
    fd="/home/pi/$d"
    if [[ ! -d $fd ]]; then
      mkdir "$fd"
      sudo chown pi:pi "$fd"
    fi 
  done    
      
  #do not force
  copy_file -s "screenly.conf" -t "/home/pi/.screenly/screenly.conf" -u pi -g pi -m 0600 -c "Copy Screenly default config"



  copy_file -s "default_assets.yml" -t "/home/pi/.screenly/default_assets.yml" -u pi -g pi -m 0600 -c "Copy Screenly default assets file"
  regex_replace_infile /home/pi/.screenly/screenly.conf '^.*listen.*' '' 'Remove deprecated parameter "listen"'
  copy_file -s "gtkrc-2.0" -t " /home/pi/.gtkrc-2.0" -u pi -g pi -m 0600 -c "Copy in GTK config"
  copy_file -s "uzbl-config" -t "/home/pi/.config/uzbl/config-screenly" -u pi -g pi -m 0600 -c "Copy in UZBL config"

  echo "Install pip dependencies"
  pip install --requirement /home/pi/screenly/requirements/requirements.txt --no-cache-dir --upgrade


  #do not force
  copy_file -s "screenly.db" -t "/home/pi/.screenly/screenly.db" -u pi -g pi -m 0600 -c "Create default assets database if does not exists"

  echo "Migrate database" && sudo -u pi python /home/pi/screenly/bin/migrate.py

  echo "Remove screenly_utils.sh" && sudo rm /usr/local/bin/screenly_utils.sh

  echo "Cleanup Cron" && sudo rm "/etc/cron.d/Cleanup screenly_assets"

  echo "Download upgrade_screenly.sh from github repository"
    sudo curl -L --output /usr/local/sbin/upgrade_screenly.sh https://raw.githubusercontent.com/Screenly/screenly-ose/master/bin/install.sh && sudo chmod 0700 /usr/local/sbin/upgrade_screenly.sh


  copy_file -s "files/screenly_overrides" -t "/etc/sudoers.d/screenly_overrides" -u root -g root -m 0440 -c "Copy screenly_overrides"
  copy_file -s "files/screenly_usb_assets.sh" -t "/usr/local/bin/screenly_usb_assets.sh" -u root -g root -m 0755 -c "Copy screenly_usb_assets.sh"
  copy_file -s "50-autoplay.rules" -t "/etc/udev/rules.d/50-autoplay.rules" -u root -g root -m 0644 -c "Installs autoplay udev rule"
  copy_file -s "/lib/systemd/system/systemd-udevd.service" -t "/etc/systemd/system/systemd-udevd.service" -u root -g root -m 0740 -c "Copy systemd-udevd service"

  regex_replace_infile /etc/systemd/system/systemd-udevd.service '^MountFlags=.+$' 'MountFlags=shared' 'Configure systemd-udevd service'


  echo "Copy screenly systemd units"
  system_d_units=('X.service' 'matchbox.service' 'screenly-celery.service' 'screenly-viewer.service' 'screenly-web.service' 'screenly-websocket_server_layer.service' 'udev-restart.service')
  for sdu in "${system_d_units[@]}"
  do
    sudo cp "./files/$sdu" "/etc/systemd/system/$sdu"
  done

  copy_file -s "plymouth-quit-wait.service" -t "/lib/systemd/system/plymouth-quit-wait.service" -u root -g root -m 0644 -c "Copy plymouth-quit-wait.service"
  copy_file -s "plymouth-quit.service" -t "/lib/systemd/system/plymouth-quit.service" -u root -g root -m 0644 -c "Copy plymouth-quit.service"

  echo "Enable Screenly systemd services"
  for sdu in "${system_d_units[@]}"
  do
    sudo systemctl enable "$sdu" chdir=/etc/systemd/system
  done
}
    
###  network
role_network () {    
  echo "Check if screenly-network-manager files exist"    
  FILE="/usr/sbin/screenly_net_mgr.py"
  if [[ -d "$FILE" ]]; then
    ### Take action if $FILE exists ###
    echo "Detected screenly-network-manager files."
    systemctl disable screenly-net-manager.service
    systemctl disable screenly-net-watchdog.timer
  else
    echo     
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


  if [[ $MANAGE_NETWORK == true ]];then
    regex_replace_infile /var/lib/polkit-1/localauthority/10-vendor.d/org.freedesktop.NetworkManager.pkla '^Identity=.*' 'Identity=unix-group:netdev;unix-group:sudo:pi' 'Add pi user to Identity'
    regex_replace_infile /var/lib/polkit-1/localauthority/10-vendor.d/org.freedesktop.NetworkManager.pkla '^ResultAny=.*' 'ResultAny=yes' 'Set ResultAny to yes'
    echo "Copy org.freedesktop.NetworkManager.pkla to 50-local.d"
    cp -f /var/lib/polkit-1/localauthority/10-vendor.d/org.freedesktop.NetworkManager.pkla /etc/polkit-1/localauthority/50-local.d
    echo "Disable dhcpcd"
    systemctl disable dhcpcd
    echo "Activate NetworkManager"
    systemctl enable NetworkManager

  fi





  if [[ $MANAGE_NETWORK == "true" ]]; then
      if [[ ! -f "/usr/local/share/wifi-connect/ui/$resin_wifi_connect_version" ]]; then
        if [[ $ansible_distribution_major_version -ge 9 ]]; then
        echo "Download resin-wifi-connect release"
        sudo curl -L --output /home/pi/resin-wifi-connect.tar "https://github.com/resin-io/resin-wifi-connect/releases/download/v$resin_wifi_connect_version/wifi-connect-v$resin_wifi_connect_version-linux-rpi.tar.gz"
      fi
    fi
  fi

  #not finished
  if [[ $MANAGE_NETWORK == "true" ]]; then
    if [[ !  -f $resin_wifi_version_file_exist ]]; then
      if [[ $ansible_distribution_major_version -ge 9 ]]; then
        sudo tar -xfv /home/pi/resin-wifi-connect.tar.gz /home/pi && chown pi:pi /home/pi/resin-wifi-connect -R
        copy_file -s "/home/pi/ui/" -t "/usr/local/share/wifi-connect/ui" -u pi -g pi -m 0755 -c "Copy 'ui' folder"
        copy_file -s "/home/pi/wifi-connect" -t "/usr/local/sbin" -u pi -g pi -m 0755 -c "Copy wifi-connect file"
        echo "Touch resin-wifi-connect version file" &&  touch "/usr/local/share/wifi-connect/ui/$resin_wifi_connect_version"
        echo "Remove unarchive files"
        sudo rm "/home/pi/wifi-connect" -r 
        sudo rm "/home/pi/ui" -r 
        sudo rm "/home/pi/resin-wifi-connect.tar.gz" -r 
      fi
    fi
  fi

  copy_file -s "wifi-connect.service" -t "/etc/systemd/system/wifi-connect.service" -u root -g root -m 0644 -c "Copy wifi-connect systemd unit"
  echo "Enable wifi-connect systemd service" && systemctl enable wifi-connect.service
  echo "Touch initialized file" && touch "/home/pi/.screenly/initialized"
}

###  splashscreen
role_splashscreen () {
      
  if [[ $VERSION_CODENAME == "jessie" ]]; then 
  # If Jessie
    if [[ $ansible_distribution_major_version -le 7 ]]; then
      sudo apt install -y fbi
      copy_file -s "splashscreen.png" -t "/etc/splashscreen.png" -u root -g root -m 0644 -c "Copies in splash screen"
      copy_file -s "asplashscreen" -t "/etc/init.d/asplashscreen" -u root -g root -m 0755 -c "Copies in rc script"
      echo "Enables asplashscreen"
      if [[ ! -d "/etc/rcS.d/S01asplashscreen" ]]; then
        update-rc.d asplashscreen defaults
      fi
    fi
    
  else 
  # If not Jessie
    if [[ $ansible_distribution_major_version -gt 7 ]]; then
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
}
    
###  nginx
role_nginx () {
  if which nginx-light &>/dev/null ; then
    echo  "Nginx-light already Installed";
  else
    echo "Installing nginx-light"
    sudo apt-get install nginx-light -y
  fi

  echo "Cleans up default config"
  sudo rm /etc/nginx/sites-enabled/default
  copy_file -s "nginx.conf" -t "/etc/nginx/sites-enabled/screenly.conf" -u root -g root -m 0644 -c "Installs nginx config"
  regex_replace_infile "/etc/systemd/system/screenly-web.service"  '^.*LISTEN.*' '' 'Modifies screenly-web service to only listen on localhost'
    
      
  ###  ssl
  if [[ -z $ENABLE_SSL ]]; then
    use_ssl=$(cat /home/pi/.screenly/screenly.conf | grep use_ssl | cut -d= -f2)
    if [[ -z $use_ssl ]] || [[ $use_ssl == 'False' ]]; then
      echo "Install nginx-light"
      sudo apt-get install nginx-light -y
      echo "Cleans up default config"
      sudo rm /etc/nginx/sites-enabled/default  
      copy_file -s "nginx.conf" -t "/etc/nginx/sites-enabled/screenly.conf" -u root -g root -m 0644 -c "Installs nginx config"
      service nginx restart
      copy_file -s "files/screenly.crt" -t "/etc/ssl/screenly.crt" -u root -g root -m 0600 -c "Installs self-signed certificates / crt"
      copy_file -s "files/screenly.key" -t "/etc/ssl/screenly.key" -u root -g root -m 0600 -c "Installs self-signed certificates / key"
      regex_replace_infile "/home/pi/.screenly/screenly.conf" '^.*use_ssl.*' 'use_ssl = True' 'Turns on the ssl mode'
      regex_replace_infile "/etc/systemd/system/screenly-web.service"  '^.*LISTEN.*' '' 'Modifies screenly-web service to only listen on localhost'
      sudo systemctl daemon-reload
      systemctl restart screenly-websocket_server_layer.service
      systemctl restart screenly-web.service
    fi
  fi 
}

###  tools
role_tools () {   

  copy_file -s "files/ngrok" -t "/usr/local/bin/" -u root -g root -m 0755 -c "Copy ngrok binary"
  copy_file -s "files/nginx.conf" -t "/etc/nginx/sites-enabled/screenly_assets.conf" -u root -g root -m 0644 -c "Installs nginx config"
}

role_system
role_rpi-update
role_screenly
role_network
role_splashscreen
role_nginx
role_tools
