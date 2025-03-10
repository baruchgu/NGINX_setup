#!/usr/bin/env bash 
############## Start Safe Header ###########################
#Develop by: Baruch Gudesblat
#Purpose: NGINX Web server setup tool
#Date: 10/03/2025
#Version: 1.0.0

############### End Safe Header ##########################


if [[ $EUID -ne 0 ]]; then
    sudo su -c "$0 $@"
    exit $?
fi


function main(){
   opt=$1
   while [[ ${opt:-} != 'q' ]]; do
      if [[ $opt == -* ]]; then
         opt=${opt:1}
      else 
         print_menu
         read -r -p "Your choose: " opt
      fi
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


#--------------------------------------------------------------
# small sub-utils
#--------------------------------------------------------------
function if_installed(){
    test -r /etc/nginx/sites-enabled/default
    return $?
}

function if_running(){
    ps ax | grep -wv grep | grep -cq 'nginx: master process'
    return $?
}

function if_ap2_running(){
    ps ax | grep -wv grep | grep -cq 'apache2 -k start'
    return $?
}

# Install it safety
function apt_install(){
    [[ -z $(apt version $1) ]] && apt install $1 -y
}

function nginx_uninstall(){
    systemctl stop nginx
    rm -rf /etc/nginx
}
#--------------------------------------------------------------
# main utils 
#--------------------------------------------------------------
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


function install_webserver(){
    if_installed   && echo "nginx Web-Server is already installed" && return 0
    if_running     && echo "nginx Web-Server is running. Stop it and rerun" && return 0
    if_ap2_running && echo "Apache2 Web-server is running. Stop it and rerun. Note: systemctl stop apache2" && return 0

    apt_install "nginx"
    # Keep the exit status
    ret=$?

    # Save the original config
    #ln -sf ../sites-available/default /etc/nginx/sites-enabled/default
    cp -p /etc/nginx/sites-available/default{,.orig}

    return $ret
}


function config_user_dir(){
    # Return if not installed
    if_installed || (echo "nginx Server is not installed" && return 0)

    cd /etc/nginx
    cat <<EOI > public_html.conf
location ~ ^/~(.+?)(/.*)?$ {
    alias /home/\$1/public_html\$2;
}
EOI
    # Add ~ location alias to user's $HOME
    awk '{print} $1 == "server_name" {print "\tinclude /etc/nginx/public_html.conf;"}' sites-enabled/default > sites-enabled/default.tmp
    mv sites-enabled/default{.tmp,}

    systemctl restart nginx
    nginx -t || echo "ERROR" && return 3

    # setup User's directory
    su $SUDO_USER -c "mkdir -p /home/$SUDO_USER/public_html; chmod 755 /home/$SUDO_USER/public_html;\
cat <<EOI > /home/$SUDO_USER/public_html/index.html 
<!DOCTYPE html>
<html> <body>
<div style=\"width: 100%; font-size: 40px; font-weight: bold; text-align: center;\">
Test Page user public_html
</div>
</body> </html>
EOI
"

    # test it. 200 is success
    curl -I http://localhost/~$SUDO_USER/index.html |& grep -wq 200
    return $?
}


function config_virtual_host(){
    if_installed || (echo "Server is not installed" && return 2)
    read -r -p "Virtual host name: " vname
    cd /etc/nginx/sites-enabled
    grep -q "^ *server_name *$vname" * && echo "$vname is already configured" && return 2

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
</body> </html>
EOI

    cat <<EOI > ../sites-available/$vname
server {
   listen 80;
   listen [::]:80;
   server_name $vname;
   root /var/www/$vname;
}
EOI

    ln -sf ../sites-available/$vname
    grep -q $vname /etc/hosts || echo "127.0.1.8	$vname" >> /etc/hosts
    # IPv6 adress to $name is skiped

    nginx -t || echo "ERROR" && return 3
    systemctl restart nginx

    # test it. 200 is success
    curl -I http://$vname/index.html |& grep -wq 200
    return $?
}


function setup_auth(){
    if_installed || (echo "Server is not installed" && return 2)

    # Install it safety
    apt_install "apache2-utils"
    apt_install "nginx-extras"

    cd /etc/nginx
    # Create passwd file
    htpasswd -b -c .htpasswd $SUDO_USER 1144

    # Add location /secure {
    cat <<EOI > secure.conf
    location /secure {
            auth_basic "Restricted Access";
            auth_basic_user_file /etc/nginx/.htpasswd;
            root /var/www/html;
            index index.html; 
        }
EOI
    awk '{print} $1 == "server_name" {print "\tinclude /etc/nginx/secure.conf;"}' sites-enabled/default > sites-enabled/default.tmp
    mv sites-enabled/default{.tmp,}
    mkdir -p "/var/www/html/secure"
    cat <<EOI > /var/www/html/secure/index.html 
<!DOCTYPE html>
<html> <body>
<div style="width: 100%; font-size: 40px; font-weight: bold; text-align: center;">
Test is the secure area
</div>
</body> </html>
EOI


    nginx -t || (echo "ERROR" && return 3)
    systemctl restart nginx

    # Test Basic Authentication
    curl -u ${SUDO_USER}:1144 -I http://localhost/secure/ |& grep -wq 200
    return $?
}


function setup_auth_PAM(){
    if_installed || (echo "Server is not installed" && return 2)

    apt_install "libpam0g-dev"
    apt_install "libpam-modules"

    cd /etc/nginx
    # Add PAM authentication
    cat <<EOI > auth-pam.conf
       location /auth-pam {
           auth_pam "PAM Authentication";
           auth_pam_service_name "nginx";
       }
EOI

    awk '{print} $1 == "server_name" {print "\tinclude /etc/nginx/auth-pam.conf;"}' sites-enabled/default > sites-enabled/default.tmp
    mv sites-enabled/default{.tmp,}

    cat <<EOI >> /etc/pam.d/nginx 
auth       include     common-auth
account    include     common-account
EOI

    usermod -aG shadow www-data

    # Reload
    nginx -t || (echo "ERROR" && return 3)
    systemctl restart nginx

    mkdir -p /var/www/html/auth-pam
    cat <<EOI > /var/www/html/auth-pam/index.html 
<!DOCTYPE html>
<html> <body>
<div style="width: 100%; font-size: 40px; font-weight: bold; text-align: center;">
Test Page for PAM Auth
</div>
</body> </html>
EOI

    # Test Basic Authentication
    curl -u ${SUDO_USER}:1144 -I http://localhost/auth-pam/ |& grep -wq 200
    return $?

}


function setup_cgi(){
    if_installed || (echo "Server is not installed" && return 2)
    apt_install "fcgiwrap"
    apt_install "spawn-fcgi"

    systemctl enable fcgiwrap --now
    systemctl start  fcgiwrap

    cd /etc/nginx
    cat <<EOI > cgi-bin.conf
    location /cgi-bin/ {
        # Specify the path to your CGI scripts
        root /usr/lib/;  # Default CGI directory
        fastcgi_pass unix:/run/fcgiwrap.socket;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;

    }
EOI

    # Add CGI config
    awk '{print} $1 == "server_name" {print "\tinclude /etc/nginx/cgi-bin.conf;"}' sites-enabled/default > sites-enabled/default.tmp
    mv sites-enabled/default{.tmp,}

    cat <<EOI > /usr/lib/cgi-bin/test.cgi
#!/usr/bin/env bash
echo "Content-type: text/html"
echo "<html><body><p><em>Shalom u Bracha. CGI scripting is UP</em></p></body></html>"
EOI
    chmod +x /usr/lib/cgi-bin/test.cgi

    # Reload
    nginx -t || (echo "ERROR" && return 3)
    systemctl restart nginx
    systemctl restart fcgiwrap

    # Test CGI scripting
    curl -I http://localhost/cgi-bin/test.cgi |& grep -wq 200
    return $?
}


#-----------------------------------------------

# Run the main as non-iteractive script
if [[ $- != *i* ]]; then
   [[ "$*" == "-h" ]] && print_menu && exit 0
   set -o errexit
   set -o pipefail
   main "$@"
   exit $?
fi

