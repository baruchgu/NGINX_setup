#!/usr/bin/env bash 
############## Start Safe Header ###########################
#Develop by: Baruch Gudesblat
#Purpose: NGINX Web server intactive setup tool
#Date: 07/03/2025
#Version: 1.0.0
set -o errexit
set -o pipefail
############### End Safe Header ##########################

#if [[ $EUID -ne 0 ]]; then
#    eval sudo su -c $0
#    exit $?
#fi


function main(){
   $opt=$1
   while [[ ${opt:-} != 'q' ]]; do
      print_menu
      read -r -p "Your choose: " opt
      case "$opt" in
         i|I) install_webserver ;;
         v|V) config_virtual_host ;;
         u|U) config_user_dir ;;
         a|A) setup_auth ;;
         p|P) setup_auth_PAM ;;
         s|S) setup_cgi ;;
         q|Q) echo "Shalom ..." ;;
      esac
   done
}

function print_menu(){
   #clear
   echo -e "\033[1mNGINX Web server setup tool:\033[0m"
   cat <<EOI
	Options:
	i) Install NGINX server 
	v) Configure Virtual Hostings
	u) Configure the user-dir
	a) Setup server authentication
	p) Setup server authentication with PAM
	s) Setup CGI scripting
	q) quit
EOI
}

#--------------------------------------------------------------
# small sub-utils
#--------------------------------------------------------------
function if_installed(){
    test ! -r /etc/nginx/sites-enabled/default
    return $?
}

function if_running(){
    return $(ps ax | grep -wv grep | grep -c 'nginx: master process')
}

function if_ap2_running(){
    return $(ps ax | grep -wv grep | grep -c 'apache2 -k start')
}

#--------------------------------------------------------------
# main utils 
#--------------------------------------------------------------
function install_webserver(){
    if_installed   || echo "Server is already installed" && return 0
    if_ap2_running || echo "Apache2 server is running. Stop it and rerun" && return 0
    if_running     || echo "Server is running. Stop it and rerun" && return 0
    echo apt-get install nginx
    return 1
}

function config_user_dir(){
    # Return if the not installed
    if_installed || echo "Server is not installed" && return 0
    # Add ~ location alias to user's $HOME
    mv sites-enabled/default{,.orig}
    awk '$1 == "location" { \
       print "\tlocation ~ ^/~(.+?)(/.*)?$  {\n\t\talias /home/$1/public_html$2;\n\t\}\n"\
    } {print}' sites-enabled/default.orig > sites-enabled/default 
    systemctl restart nginx

    # setup User's directory
    su $SUDO_USER -c "mkdir /home/$SUDO_USER/public_html; chmod 755 /home/$SUDO_USER/public_html"

    # test it. 200 is success
    curl -I http://localhost/~$SUDO_USER | grep -wq 200
    return $?
}

function config_virtual_host(){
    if_installed || echo "Server is not installed"
    read -r -p "Virtual host name: " vname
    cd /etc/nginx/sites-enabled
    [[ -r $name ]] && echo "$vname is already configured" && return 2
    mkdir -p /var/www/$vname
    cat <<EOI > /var/www/$vname/index.html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx as $vname server</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
EOI

    cat <<EOI > ../sites-available/$vname
server {
       listen 80;
       listen [::]:80;
       server_name $vname;
       root /var/www/$vname;
       index index.html;
       location / {
           try_files $uri $uri/ =404;
       }

EOI
    ln -s ../sites-available/$vname
    echo "127.0.1.8	$vname" >> /etc/hosts
    systemctl restart nginx

    # test it. 200 is success
    curl -I http://localhost/~$SUDO_USER | grep -wq 200
    return $?
}

function setup_auth(){
    if_installed || echo "Server is not installed"
}

function setup_auth_PAM(){
    if_installed || echo "Server is not installed"
}

function setup_cgi(){
    if_installed || echo "Server is not installed"
}


main "$@"

