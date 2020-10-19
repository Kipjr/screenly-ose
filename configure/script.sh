#!/bin/bash


###
### VARS
###

skip-tags 
enable-ssl
system-upgrade

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







- debug:
    msg: "Use cmdline.txt.orig for boot parameters (don't remove this file)"
  when: not is_berryboot

- copy:
    src: /boot/cmdline.txt.orig
    dest: /boot/cmdline.txt
    force: yes
  when: not is_berryboot and config_txt.stdout.find('NOOBS') == -1
  tags:
    - touches_boot_partition







# Sometimes in some packages there are no necessary files.
# They are required to install pip dependencies.
# In this case we need to reinstall the packages.
- name: Check if cdefs.h exists
  stat:
    path: /usr/include/arm-linux-gnueabihf/sys/cdefs.h
  register: cdefs

- set_fact: cdefs_exist="{{cdefs.stat.exists}}"

- name: Remove libc6-dev
  apt:
    name: libc6-dev
    state: absent
  when: not cdefs_exist

- name: Install libc6-dev
  apt:
    name: libc6-dev
    state: present
    update_cache: yes
  when: not cdefs_exist

- name: Check if cc1plus exists
  stat:
    path: /usr/lib/gcc/arm-linux-gnueabihf/4.9/cc1plus
  register: cc1plus

- set_fact: cc1plus_exist="{{cc1plus.stat.exists}}"

- name: Remove build-essential
  apt:
    name: build-essential
    state: absent
  when: not cc1plus_exist

- name: Install build-essential
  apt:
    name: build-essential
    state: present
    update_cache: yes
  when: not cc1plus_exist

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


- name: Remove deprecated pip dependencies
  pip:
    name: supervisor
    state: absent

copy_file "rc.local"  "/etc/rc.local" root root 0755 "Copy in rc.local"
copy_file "01_nodoc"  "/etc/dpkg/dpkg.cfg.d/01_nodoc" root root 0644 "Copy in 01_nodoc"
copy_file "10-evdev.conf"  "/usr/share/X11/xorg.conf.d/10-evdev.conf" root root 0644 "Copy in evdev"
copy_file "10-serverflags.conf"  "/usr/share/X11/xorg.conf.d/10-serverflags.conf" root root 0644 "Disable DPMS"



- name: Clear out X11 configs (disables touchpad and other unnecessary things)
  file:
    path: "/usr/share/X11/xorg.conf.d/{{ item }}"
    state: absent
  with_items:
    - 50-synaptics.conf
    - 10-quirks.conf
    - 50-wacom.conf

- name: Disable swap
  command: /sbin/swapoff --all removes=/var/swap

- name: Remove swapfile from disk
  file:
    path: /var/swap
    state: absent
  
    
    
    
###  rpi-update
    
    
    
    ---

- name: Download rpi-update
  get_url:
    url: https://raw.githubusercontent.com/Hexxeh/rpi-update/master/rpi-update
    dest: /usr/bin/rpi-update
    mode: 0755
    owner: root
    group: root
  when: ansible_distribution_release == "wheezy"

- name: Run kernel upgrade (this can take up to 10 minutes)
  command: /usr/bin/rpi-update
  when: ansible_distribution_release == "wheezy"
  environment:
    SKIP_WARNING: 1
  register: rpiupdate
  tags:
    - system-upgrade

- debug: msg="{{ rpiupdate.stdout }}"
  when: ansible_distribution_release == "wheezy"
  tags:
    - system-upgrade

    
    
###  screenly
    
    
    - name: Ensure folders exist
  file:
    path: "/home/pi/{{ item }}"
    state: directory
    owner: pi
    group: pi
  with_items:
    - .screenly
    - .config
    - .config/uzbl

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

- name: Run database migration
  become_user: pi
  command: python /home/pi/screenly/bin/migrate.py
  register: migrate

- debug: msg="{{ migrate.stdout }}"

- name: Remove screenly_utils.sh
  file:
    state: absent
    path: /usr/local/bin/screenly_utils.sh

- cron:
    name: Cleanup screenly_assets
    state : absent
    user: pi

- name: Download upgrade_screenly.sh from github repository
  get_url:
    url: https://raw.githubusercontent.com/Screenly/screenly-ose/master/bin/install.sh
    dest: /usr/local/sbin/upgrade_screenly.sh
    mode: 0700
    owner: root
    group: root
    force: yes



copy_file "files/screenly_overrides"  "/etc/sudoers.d/screenly_overrides" root root 0440 "Copy screenly_overrides"
copy_file "files/screenly_usb_assets.sh"  "/usr/local/bin/screenly_usb_assets.sh" root root 0755 "Copy screenly_usb_assets.sh"
copy_file "50-autoplay.rules"  "/etc/udev/rules.d/50-autoplay.rules" root root 0644 "Installs autoplay udev rule"
copy_file "/lib/systemd/system/systemd-udevd.service"  "/etc/systemd/system/systemd-udevd.service" root root 0740 "Copy systemd-udevd service"

regex_replace_infile /etc/systemd/system/systemd-udevd.service '^MountFlags=.+$' 'MountFlags=shared' 'Configure systemd-udevd service'

- name: Copy screenly systemd units
  copy:
    src: "{{ item }}"
    dest: "/etc/systemd/system/{{ item }}"
  with_items: "{{ screenly_systemd_units }}"


copy_file "plymouth-quit-wait.service"  "/lib/systemd/system/plymouth-quit-wait.service" root root 0644 "Copy plymouth-quit-wait.service"
copy_file "plymouth-quit.service"  "/lib/systemd/system/plymouth-quit.service" root root 0644 "Copy plymouth-quit.service"


- name: Enable screenly systemd services
  command: systemctl enable {{ item }} chdir=/etc/systemd/system
  with_items: "{{ screenly_systemd_units }}"

    
    
    
###  network
    
    
    
    
    - name: Check if screenly-network-manager files exist
  stat:
    path: /usr/sbin/screenly_net_mgr.py
  register: screenly_network_manager

- set_fact: screenly_network_manager_exist="{{screenly_network_manager.stat.exists}}"

- name: Disable network manager
  command: systemctl disable screenly-net-manager.service
  when: screenly_network_manager_exist

- name: Disable network watchdog
  command: systemctl disable screenly-net-watchdog.timer
  when: screenly_network_manager_exist

- name: Remove network manger and watchdog
  file:
    state: absent
    path: "/usr/sbin/{{ item }}"
  with_items:
    - screenly_net_mgr.py
    - screenly_net_watchdog.py

- name: Remove network manager and watchdog unit files
  file:
    state: absent
    path: "/etc/systemd/system/{{ item }}"
  with_items:
    - screenly-net-manager.service
    - screenly-net-watchdog.service

- name: Remove network watchdog timer file
  file:
    state: absent
    path: /etc/systemd/system/screenly-net-watchdog.timer

# Use resin-wifi-connect if Stretch
- debug:
    msg: "Manage network: {{ manage_network }}"

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

- name: Unarchive resin-wifi-connect release
  unarchive:
    src: /home/pi/resin-wifi-connect.tar.gz
    dest: /home/pi
    owner: pi
    group: pi
  when:
    - ansible_distribution_major_version|int >= 9
    - not resin_wifi_version_file_exist
    - manage_network|bool == true

- name: Copy "ui" folder
  copy:
    src: /home/pi/ui/
    dest: /usr/local/share/wifi-connect/ui
    mode: 0755
  when:
    - ansible_distribution_major_version|int >= 9
    - not resin_wifi_version_file_exist
    - manage_network|bool == true

- name: Copy wifi-connect file
  copy:
    src: /home/pi/wifi-connect
    dest: /usr/local/sbin
    mode: 0755
  when:
    - ansible_distribution_major_version|int >= 9
    - not resin_wifi_version_file_exist
    - manage_network|bool == true

- name: Touch resin-wifi-connect version file
  file:
    state: touch
    path: "/usr/local/share/wifi-connect/ui/{{ resin_wifi_connect_version }}"
  when:
    - ansible_distribution_major_version|int >= 9
    - not resin_wifi_version_file_exist
    - manage_network|bool == true

- name: Remove unarchive files
  file:
    state: absent
    path: "/home/pi/{{ item }}"
  with_items:
    - wifi-connect
    - ui
    - resin-wifi-connect.tar.gz
  when:
    - ansible_distribution_major_version|int >= 9
    - not resin_wifi_version_file_exist
    - manage_network|bool == true

copy_file "wifi-connect.service"  "/etc/systemd/system/wifi-connect.service" root root 0644 "Copy wifi-connect systemd unit"



- name: Enable wifi-connect systemd service
  systemd:
    name: wifi-connect.service
    enabled: yes

- name: Touch initialized file
  file:
    state: touch
    path: "/home/pi/.screenly/initialized"




###  splashscreen
    
   ---

# If Jessie
- name: Installs dependencies (Jessie)
  apt:
    name:
	fbi
  when: ansible_distribution_major_version|int <= 7

- name: Copies in splash screen
  copy:
    src: splashscreen.png
    dest: /etc/splashscreen.png
  when: ansible_distribution_major_version|int <= 7

- name: Copies in rc script
  copy:
    src: asplashscreen
    dest: /etc/init.d/asplashscreen
    mode: 0755
  when: ansible_distribution_major_version|int <= 7

- name: Enables asplashscreen
  command: update-rc.d asplashscreen defaults
  args:
    creates: /etc/rcS.d/S01asplashscreen
  when: ansible_distribution_major_version|int <= 7

# If not Jessie

- name: Remove older versions
  file:
    state: absent
    path: "{{ item }}"
  with_items:
    - /etc/splashscreen.jpg
    - /etc/init.d/asplashscreen
  when: ansible_distribution_major_version|int > 7

- name: Disable asplashscreen
  command: update-rc.d asplashscreen remove
  when: ansible_distribution_major_version|int > 7

- name: Installs dependencies (not Jessie)
  apt:
    name:
	plymouth
	pix-plym-splash
  when: ansible_distribution_major_version|int > 7

- name: Copies plymouth theme
  copy:
    src: "{{ item }}"
    dest: /usr/share/plymouth/themes/screenly/
  with_items:
    - screenly.plymouth
    - screenly.script
    - splashscreen.png
  when: ansible_distribution_major_version|int > 7

- name: Set splashscreen
  command: plymouth-set-default-theme -R screenly
  when: ansible_distribution_major_version|int > 7

- name: Set plymouthd.default
  copy:
    src: plymouthd.default
    dest: /usr/share/plymouth/plymouthd.default
  when: ansible_distribution_major_version|int > 7
 
    
    
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