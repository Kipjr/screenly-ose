
skip-tags 
enable-ssl
system-upgrade




copy_file () {
 # source target owner group flags
 #
 #
  str="Copying $1 to $2"
  if [ ! -z $1 ] && [ ! -z $2 ]; then
    cp $1 $2 -f 
    if [ ! -z $3 ] && [ ! -z $4 ];then 
      chown $3:$4 $2
      str+=" as $3:$4"
    fi
    if [ ! -z $5 ];then 
      chmod $5 $2
      str+=" with $5 flags"
    fi
    echo "$str"
  else 
    echo "Not enough arguments"
  fi
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
    - system
    
    
  
#- name: test for available disk space
#  assert:
#    that:
#     - "{{ item.size_available > 500 * 1000 * 1000 }}" # 500Mb
#  when: "{{ item.mount == '/' }}"
#  with_items: "{{ ansible_mounts }}"


# We need custom handling for BerryBoot as it lacks `/boot`.
# To detect this, the image creates `/etc/berryboot`.
- stat:
    path: /etc/berryboot
  register: berryboot

- set_fact: is_berryboot="{{berryboot.stat.exists}}"

- debug:
    msg: "Detected BerryBoot installation. Skipping some steps."
  when: is_berryboot

- name: Check NOOBS
  command: cat /boot/config.txt
  register: config_txt
  tags:
    - touches_boot_partition


- name: Make sure we have proper framebuffer depth
  lineinfile:
    dest: /boot/config.txt
    regexp: ^framebuffer_depth=
    line: framebuffer_depth=32
  when: not is_berryboot
  tags:
    - touches_boot_partition

- name: Fix framebuffer bug
  lineinfile:
    dest: /boot/config.txt
    regexp: ^framebuffer_ignore_alpha=
    line: framebuffer_ignore_alpha=1
  when: not is_berryboot
  tags:
    - touches_boot_partition

- name: Backup kernel boot args
  copy:
    src: /boot/cmdline.txt
    dest: /boot/cmdline.txt.orig
    force: no
  when: not is_berryboot
  tags:
    - touches_boot_partition

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

- name: For splash screen using Plymouth
  replace:
    dest: /boot/cmdline.txt
    regexp: (^(?!$)((?!splash).)*$)
    replace: \1 splash
  when: not is_berryboot and ansible_distribution_major_version|int >= 7

- name: Remove blinking cursor
  replace:
    dest: /boot/cmdline.txt
    regexp: (^(?!$)((?!vt.global_cursor_default=0).)*$)
    replace: \1 vt.global_cursor_default=0
  when: not is_berryboot and ansible_distribution_major_version|int >= 7
  tags:
    - touches_boot_partition

- name: Use Systemd as init and quiet boot process
  replace:
    dest: /boot/cmdline.txt
    regexp: (^(?!$)((?!quiet init=/lib/systemd/systemd).)*$)
    replace: \1 quiet init=/lib/systemd/systemd
  when: not is_berryboot
  tags:
    - touches_boot_partition

- name: ethN/wlanN names for interfaces
  replace:
    dest: /boot/cmdline.txt
    regexp: (^(?!$)((?!net\.ifnames=0).)*$)
    replace: \1 net.ifnames=0
  when: not is_berryboot
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

- name: Copy in rc.local
  copy:
    src: rc.local
    dest: /etc/rc.local
    mode: 0755
    owner: root
    group: root

- name: Copy in 01_nodoc
  copy:
    src: 01_nodoc
    dest: /etc/dpkg/dpkg.cfg.d/01_nodoc
    mode: 0644
    owner: root
    group: root

- name: Copy in evdev
  copy:
    src: 10-evdev.conf
    dest: /usr/share/X11/xorg.conf.d/10-evdev.conf
    mode: 0644
    owner: root
    group: root

- name: Disable DPMS
  copy:
    src: 10-serverflags.conf
    dest: /usr/share/X11/xorg.conf.d/10-serverflags.conf
    mode: 0644
    owner: root
    group: root

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
  
    
    
    
    - rpi-update
    
    
    
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

    
    
    - screenly
    
    
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

- name: Copy Screenly default config
  copy:
    owner: pi
    group: pi
    src: screenly.conf
    dest: /home/pi/.screenly/screenly.conf
    force: no

- name: Copy Screenly default assets file
  copy:
    owner: pi
    group: pi
    src: default_assets.yml
    dest: /home/pi/.screenly/default_assets.yml
    force: yes

- name: Remove deprecated parameter "listen"
  lineinfile:
    regexp: '^.*listen.*'
    state: absent
    dest: /home/pi/.screenly/screenly.conf

- name: Copy in GTK config
  copy:
    owner: pi
    group: pi
    src: gtkrc-2.0
    dest: /home/pi/.gtkrc-2.0

- name: Copy in UZBL config
  copy:
    owner: pi
    group: pi
    src: uzbl-config
    dest: /home/pi/.config/uzbl/config-screenly

- name: Install pip dependencies
  pip:
    requirements: /home/pi/screenly/requirements/requirements.txt
    extra_args: "--no-cache-dir --upgrade"

- name: Create default assets database if does not exists
  copy:
    owner: pi
    group: pi
    src: screenly.db
    dest: /home/pi/.screenly/screenly.db
    force: no

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

- name: Copy screenly_overrides
  copy:
    src: screenly_overrides
    dest: /etc/sudoers.d/screenly_overrides
    mode: 0440
    owner: root
    group: root

- name: Copy screenly_usb_assets.sh
  copy:
    src: screenly_usb_assets.sh
    dest: /usr/local/bin/screenly_usb_assets.sh
    mode: 0755
    owner: root
    group: root

- name: Installs autoplay udev rule
  copy:
    src: 50-autoplay.rules
    dest: /etc/udev/rules.d/50-autoplay.rules
    mode: 644
    owner: root
    group: root

- name: Copy systemd-udevd service
  copy:
    src: /lib/systemd/system/systemd-udevd.service
    dest: /etc/systemd/system/systemd-udevd.service

- name: Configure systemd-udevd service
  lineinfile:
    dest: /etc/systemd/system/systemd-udevd.service
    regexp: '^MountFlags='
    line: 'MountFlags=shared'

- name: Copy screenly systemd units
  copy:
    src: "{{ item }}"
    dest: "/etc/systemd/system/{{ item }}"
  with_items: "{{ screenly_systemd_units }}"

- name: Copy plymouth-quit-wait.service
  copy:
    src: plymouth-quit-wait.service
    dest: /lib/systemd/system/plymouth-quit-wait.service
    mode: 0644
    owner: root
    group: root

- name: Copy plymouth-quit.service
  copy:
    src: plymouth-quit.service
    dest: /lib/systemd/system/plymouth-quit.service
    mode: 0644
    owner: root
    group: root

- name: Enable screenly systemd services
  command: systemctl enable {{ item }} chdir=/etc/systemd/system
  with_items: "{{ screenly_systemd_units }}"

    
    
    
    - network
    
    
    
    
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

- name: Add pi user to Identity
  replace:
    regexp: '^Identity=.*'
    replace: 'Identity=unix-group:netdev;unix-group:sudo:pi'
    dest: /var/lib/polkit-1/localauthority/10-vendor.d/org.freedesktop.NetworkManager.pkla
  when:
    - manage_network|bool == true

- name: Set ResultAny to yes
  replace:
    regexp: '^ResultAny=.*'
    replace: 'ResultAny=yes'
    dest: /var/lib/polkit-1/localauthority/10-vendor.d/org.freedesktop.NetworkManager.pkla
  when:
    - manage_network|bool == true

- name: Copy org.freedesktop.NetworkManager.pkla to 50-local.d
  command: cp -f /var/lib/polkit-1/localauthority/10-vendor.d/org.freedesktop.NetworkManager.pkla /etc/polkit-1/localauthority/50-local.d
  when:
    - manage_network|bool == true

- name: Disable dhcpcd
  command: systemctl disable dhcpcd
  when:
    - ansible_distribution_major_version|int >= 9
    - manage_network|bool == true

- name: Activate NetworkManager
  command: systemctl enable NetworkManager
  when:
    - ansible_distribution_major_version|int >= 9
    - manage_network|bool == true

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

- name: Copy wifi-connect systemd unit
  copy:
    src: "wifi-connect.service"
    dest: "/etc/systemd/system/wifi-connect.service"

- name: Enable wifi-connect systemd service
  systemd:
    name: wifi-connect.service
    enabled: yes

- name: Touch initialized file
  file:
    state: touch
    path: "/home/pi/.screenly/initialized"




    - splashscreen
    
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
 
    
    
    - nginx
    
    
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

- name: Installs nginx config
  copy:
    src: nginx.conf
    dest:  /etc/nginx/sites-enabled/screenly.conf
    mode: 644
    owner: root
    group: root

- name: Modifies screenly-web service to only listen on localhost
  lineinfile:
    regexp: '^.*LISTEN.*'
    state: absent
    dest: /etc/systemd/system/screenly-web.service
  when: no_ssl

    
    
    
    - ssl
    
    
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

- name: Installs nginx config
  copy:
    src: nginx.conf
    dest:  /etc/nginx/sites-enabled/screenly.conf
    mode: 644
    owner: root
    group: root
  notify:
    - restart-nginx
  tags:
    - enable-ssl

- name: Installs self-signed certificates
  copy:
    src: "{{ item }}"
    dest: "/etc/ssl/{{ item }}"
    mode: 0600
    owner: root
    group: root
    force: no
  with_items:
    - screenly.crt
    - screenly.key
  tags:
    - enable-ssl

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
  
    
    
    - tools
    
    
    
    - name: Copy ngrok binary
  copy:
    src: ngrok
    dest: /usr/local/bin/
    mode: 0755
    owner: root
    group: root

- name: Installs nginx config
  copy:
    src: nginx.conf
    dest:  /etc/nginx/sites-enabled/screenly_assets.conf
    mode: 644
    owner: root
    group: root

