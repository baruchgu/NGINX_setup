#!/usr/bin/env bash 
############## Start Safe Header ###########################
#Develop by: Baruch Gudesblat
#Purpose: NGINX Web server intactive setup tool
#Date: 07/03/2025
#Version: 1.0.0
set -o errexit
set -o pipefail
############### End Safe Header ##########################

function main(){
   while [[ ${opt:-} != 'q' ]]; do
      print_menu
      read -r -p "Your choose: " opt
      case "$opt" in
         i|I) echo install_webserver ;;
         u|U) echo config_user_dir ;;
         v|V) echo config_virtual_host ;;
         a|A) echo setup_auth ;;
         p|P) echo setup_auth_PAM ;;
         s|S) echo setup_cgi ;;
         q|Q) echo "Shalom ..." ;;
      esac
   done
}

function print_menu(){
   clear
   echo -e "\033[1mNGING Web server setup tool:\033[0m"
   cat <<EOI
	Options:
	i) Install NGINX server 
	u) Configure the user-dir
	v) Configure Virtual Hostings
	a) Setup server authentication
	p) Setup server authentication with PAM
	s) Setup CGI scripting
	q) exit
EOI
}

#--------------------------------------------------------------
function if_installed(){
    test ! -r /etc/nginx/sites-enabled/default
    return $?
}

function if_running(){
    return $(ps ax | grep -wv grep | grep -c 'nginx: master process')
}

#--------------------------------------------------------------

main "$@"

