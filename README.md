[![Test](https://img.shields.io/badge/NGINX%20setup%20tool-8A2BE2)]([https://](https://img.shields.io/badge/NGINX%20setup%20tool-8A2BE2))
[![GitHub contributors](https://img.shields.io/github/contributors/baruchgu/nginx_setup)](https://github.com/baruchgu/nginx_setup/graphs/contributors)
[![GitHub issues](https://img.shields.io/github/issues/coderjojo/creative-profile-readme)](https://github.com/baruchgu/nginx_setup/issues)

# NGINX setup tool
![NGINX logo](assets/NGINX.png)

---

## Project Overview
Automated way to setup and configure NGINX Web server on Linux VMWare machine without manual steps.   
✅ check if Nginx is installed. If not - install   
✅ setup user-directories    
✅ setup virtual host domain with name gived by promt  
✅ setup authentication  
✅ setup authentication with PAM  
✅ setup CGI scripting ability  
✅ Interactive and CLI input arguments are supported  
✅ The tool runs under the root credentials, if not root - sudo is used   
✅ Correct exit status is provided. 0 - sucess, else - fails.

## 📁 Folder Structure
- **📁 <span style="display: inline-block; margin-right: 20px;">[nginx_setup/](./)</span>** Root directory  
  - 📄 <span style="display: inline-block; margin-right: 20px;">[README](./README.md)</span> Project overview, usage, installation instructions  
  - 📄 <span style="display: inline-block; margin-right: 20px;">[LICENSE](./LICENSE)</span> Open-source license  
  - 📄 <span style="display: inline-block; margin-right: 20px;">[TASK](./TASK.md)</span> Task description  
  - 📄 <span style="display: inline-block; margin-right: 20px;">[CONTRIBUTORS](./CONTRIBUTORS.md)</span>
  - 📄 <span style="display: inline-block; margin-right: 20px;">[webserver_setup](./webserver_setup.sh)</span> Main script for Nginx setup (bash)  

## Getting Started
### Pre-Requisites:
Ensure that your system meets the following requirements:
- Bash, git and curl installed
- Linux based system

### Cloning the Repository:
- How to clone the repository:
```bash
git clone https://github.com/baruchgu/nginx_setup.git
cd nginx_setup
```
### Running the Setup:
- Steps to run the setup tool:
```bash
chmod +x webserver_setup.sh
./webserver_setup.sh
```
## Dependecies
During the run the tool installs the following packages  
✅ nginx  
✅ apache2-utils  
✅ nginx-extras  
✅ libpam0g-dev  
✅ libpam-modules  
✅ fcgiwrap  
✅ spawn-fcgi  

## Usage and Examples:

### Help:
Print the usage menu and exit
```bash
./webserver_setup.sh -h  
``` 
Output:
```bash
NGINX Web server setup tool:
	Options:
	i) Install NGINX server 
	v) Configure Virtual Hostings
	u) Configure the user-dir
	a) Setup server authentication
	p) Setup server authentication with PAM
	s) Setup CGI scripting
	q) quit
```

### CLI arguments:

```bash
./webserver_setup.sh -i  #Install NGINX server
./webserver_setup.sh -v  #Configure Virtual Hostings
./webserver_setup.sh -u  #Configure the user-dir
./webserver_setup.sh -a  #Setup server authentication
./webserver_setup.sh -p  #Setup server authentication with PAM
./webserver_setup.sh -s  #Setup CGI scripting
``` 

## License
[License](./LICENSE)

## 🙇 Credit
Many of code and ideas were copied from README files of [Tal](https://github.com/mendelsontal) in his GitHub projects. Thanks :+1:

