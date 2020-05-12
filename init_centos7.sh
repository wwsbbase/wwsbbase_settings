#!/bin/bash
#####		一键初始化CentOS7		 #####
#####		Update:2020-5-12		#####


# 文件夹结构
sambaFolder="/data/"

system_hostname="defaut_hostname"
system_username="defaut_user"

setUserColor=""
python_lib_path=""
python3_lib_path=""

function BaseSetting()
{
	echo '----------------------------------'
	echo 'BaseSetting begin'
	############# Add User ############
	#sudo adduser defaut_user
	#sudo passwd defaut_user
	#sudo visudo

	########## Base Setting ###########
	SetHostname
	SetConsoleColor

	# 安装字符集
	# locale-gen en_US.UTF-8
	echo 'BaseSetting end'
	echo '----------------------------------'
}

###
# Set host name
###
function SetHostname()
{
	sudo hostnamectl set-hostname $system_hostname
	sudo echo "127.0.1.1   ${system_hostname}" >> /etc/hosts
}


###
# Set Console Color
###
function SetConsoleColor()
{
	# set PS1
	echo $setUserColor >> $userFolder/.bashrc
	sudo echo $setRootColor >> /root/.bashrc
}

###
# Close selinux services
###
function CloseSelinxServices()
{
	/bin/sed -i 's/mingetty tty/mingetty --noclear tty/' /etc/inittab
	/bin/sed -i 's/SELINUX=permissive/SELINUX=disabled/' /etc/selinux/config
	/bin/sed -i 's/SELINUX=enforcing/SELINUX=disabled/'  /etc/selinux/config
}

###
# Close unuseful services
###
function CloseUnusefulServices()
{
	systemctl disable 'postfix'
	systemctl disable 'NetworkManager'
	systemctl disable 'abrt-ccpp'
}

###
# Public key
###
function SetPublicKey()
{
	mkdir /root/.ssh
	pub_key='ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA4mvukv4f5seBuzrCnCCm1DpSgYw/kvq+XgsUP8mnzUpyaQ6D8BKfbOn6T20tUU/ksiJwSuUQHfw5v9JsnBACto3o/RmId0Ltn4DCq19sSwMP3YJb9dRb8SA/Pc5Xl7MPwPoSYyuY20ztMfo1GBx5N9dDuQ3j1MdKYTY9SdfFwPr0ZQvesKT1ozfQ9HHrcUi1CLJw+irYW9+jU39CsMrrZmCjb/n53gP77Do0lj9TkqXK2SYNdA88cmK2IQJP3LfFWWrwYH01FkImZbt7ODDQ21BqGccLY7xCbsNaniBlT8Mpy4/Wlg1qqnNPxBbw1nrs9A+2MnAfGDHXYhkFC/n6wQ== root@linux.jesonc.net'
	echo $pub_key >> /root/.ssh/authorized_keys
	chmod 700 /root/.ssh
	chmod 600 /root/.ssh/authorized_keys
	chown -R root:root /root/.ssh
}

###
# Sysctl config 
###
function SysctlConfig()
{

found=`grep -c net.ipv4.tcp_tw_recycle /etc/sysctl.conf`
if ! [ $found -gt "0" ]
then
cat > /etc/sysctl.conf << EOF
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
fs.file-max = 131072
kernel.panic=1
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1
net.core.netdev_max_backlog = 3072
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_max_tw_buckets = 720000
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_fin_timeout = 5
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_retries1 = 2
net.ipv4.tcp_retries2 = 10
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_syncookies = 1
EOF
fi

sysctl -p
}


###
# Max open files
###
function SetMaxOpenFiles()
{
	found=`grep -c "^* soft nproc" /etc/security/limits.conf`
	if ! [ $found -gt "0" ]
	then
cat >> /etc/security/limits.conf << EOF
* soft nproc 2048
* hard nproc 16384
* soft nofile 8192
* hard nofile 65536
EOF
	fi
}

###
# ssh config
###
/bin/sed -i 's/.*Port[[:space:]].*$/Port 9922/' /etc/ssh/ssh_config
/bin/sed -i 's/.*Port[[:space:]].*$/Port 9922/' /etc/ssh/sshd_config
/bin/sed -i 's/port=\"22\"/port=\"9922\"/' /usr/lib/firewalld/services/ssh.xml 
firewall-cmd --reload


###
# Command History
###
function SetHistory()
{
	found=`grep -c HISTTIMEFORMAT /etc/profile`
	if ! [ $found -gt "0" ]
	then
	echo "export HISTSIZE=2000" >> /etc/profile
	echo "export HISTTIMEFORMAT='%F %T:'" >> /etc/profile
	fi
}



function InstallTools()
{
	echo '----------------------------------'
	echo 'InstallTools begin'
	InstallBaseTools
	InstallAdvanceTools
	echo 'InstallTools end'
	echo '----------------------------------'
}

function InstallBaseTools()
{
	echo '----------------------------------'
	echo 'InstallBaseTools begin'
	# install base tools

	sudo yum install -y  epel-release
	sudo yum install -y  htop
	sudo yum install -y  subversion
	sudo yum install -y  git
	sudo yum install -y  wget
	sudo yum install -y  unzip
	sudo yum install -y  screen
	sudo yum install -y  dstat
	sudo yum install -y  curl
	sudo yum install -y  ntpdate
	sudo yum install -y  gdisk
	sudo yum install -y	 net-tools
	echo 'InstallBaseTools end'
	echo '----------------------------------'
}

function InstallAdvanceTools()
{
	echo '----------------------------------'
	echo 'InstallAdvanceTools begin'

	# file system
	sudo yum install -y  xfsprogs


	sudo yum install -y  python3
	sudo yum install -y  python3-dev

	sudo yum install -y  python-pip
	sudo yum install -y  python3-pip


	echo 'InstallAdvanceTools end'
	echo '----------------------------------'
}

function InstallExtraService()
{
	# Services
	sudo yum install -y  samba samba-common-bin
	sudo yum install -y  aria2
	sudo yum install -y  nginx
}

function InstallMariaDB()
{
	# 配置源
	sudo cp "${operatorFolder}wwsbbase_settings/MariaDB.repo" "/etc/yum.repos.d/MariaDB.repo"
	yum install -y MariaDB-server MariaDB-client
}

# 重新获取一份配置，方便其他服务从固定位置获取配置
function FetchConfigs()
{
	echo '----------------------------------'
	echo 'FetchConfigs begin'
	# 下载各种配置文件
	if [ ! -d "$operatorFolder" ]; then
		mkdir -p "$operatorFolder"
	fi

	cd "$operatorFolder"
	#wget https://codeload.github.com/wwsbbase/wwsbbase_settings/zip/master
	#unzip master
	git clone https://github.com/wwsbbase/wwsbbase_settings.git

	echo 'FetchConfigs end'
	echo '----------------------------------'
}

function PythonEnvs()
{
	# pip 换源
	mkdir $userFolder/.pip
	sudo cp "${operatorFolder}wwsbbase_settings/pip.conf" $userFolder/.pip/pip.conf

	sudo pip install virtualenvwrapper
	sudo pip3 install virtualenvwrapper

	mkdir $userFolder/.virtualenvs
	echo "export WORKON_HOME=~/.virtualenvs" >> $userFolder/.bashrc
	echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3" >> $userFolder/.bashrc
	echo "source /usr/local/bin/virtualenvwrapper.sh" >> $userFolder/.bashrc
}

function InstallZlua()
{
	echo '----------------------------------'
	echo 'InstallZlua begin'
	cd "$operatorFolder"
	git clone https://github.com/skywind3000/z.lua.git

	echo "eval \"\$(lua $operatorFolder/z.lua/z.lua --init bash enhanced once)\"" >> $userFolder/.bashrc

	echo 'InstallZlua end'
	echo '----------------------------------'
}

function SambaService()
{
	echo '----------------------------------'
	echo 'SambaService begin'
	sudo mv /etc/samba/smb.conf /etc/samba/smb_bak.conf

	# 配置/etc/samba/smb.conf文件
	# cd "${operatorFolder}wwsbbase_settings"
	# sudo cp smb.conf /etc/samba/smb.conf
	sudo cp "${operatorFolder}wwsbbase_settings/smb.conf" /etc/samba/smb.conf

	if [ ! -d "$sambaFolder" ]; then
		mkdir -p "$sambaFolder"
	fi

	sudo chown -R ${system_username}:${system_username} "$sambaFolder"
	sudo smbpasswd -a ${system_username}

	#设置开机自启动，编辑/etc/rc.local

	#重新启动服务
	sudo /etc/init.d/samba restart

	echo 'SambaService end'
	echo '----------------------------------'
}

function UserSetting()
{
	echo '########## UserSetting ##########'
}

function CentOS()
{
	echo '########## CentOS ##########'
	########## BaseSetting ###########
	BaseSetting
	InstallBaseTools
	FetchConfigs
	############## Vim ################
	BuildVim
	BuildYcm
	######### UserSetting #############
	UserSetting
	InstallZlua
	############## Service ################
	# SambaServic
	InstallMariaDB
}

function CentOS_Lite()
{
	echo '########## CentOS_Lite ##########'
	########## BaseSetting ###########
	BaseSetting
	InstallBaseTools
	FetchConfigs
	############## Vim ################
	# BuildVim
	# BuildYcm
	######### UserSetting #############
	UserSetting
	InstallZlua	
}

function OneStepFunction()
{
	echo '########## OneStepFunction ##########'
	echo ${operatorFolder}
}

function InputHostNameAndUserName()
{
	echo '-----------------------------'
	echo '请输入HostName:'
	echo '-----------------------------'
	read -p ":" system_hostname
	echo '-----------------------------'
	echo '输入的HostName:'
	echo '-----------------------------'
	echo ${system_hostname}


	echo '-----------------------------'
	echo '请输入UserName:'
	echo '-----------------------------'
	read -p ":" system_username
	echo '-----------------------------'
	echo '输入的HostName:'
	echo '-----------------------------'
	echo ${system_username}

	rootName="root"
	if [ ${system_username} == ${rootName} ] 
	then
		userFolder="/root/"
		operatorFolder="/root/download/"
	else
		userFolder="/home/${system_username}"
		operatorFolder="/home/${system_username}/download/"
	fi

	echo '-----------------------------'
	echo '当前用户目录为:'
	echo '-----------------------------'
	echo ${userFolder}

	echo '-----------------------------'
	echo '当前操作目录为:'
	echo '-----------------------------'
	echo ${operatorFolder}
}

echo '#####		欢迎使用一键初始化Linux脚本^_^		#####'
echo '#####									  	  #####'
echo '#####		请使用 普通账号的sudo 进行初始化!!!	#####'
echo '#####		请使用 普通账号的sudo 进行初始化!!!	#####'
echo '#####		请使用 普通账号的sudo 进行初始化!!!	#####'
echo '#####									      #####'
echo '---------------------------------------------'
echo '请选择系统:'
echo "1) CentOS 7 X64"
echo "2) CentOS 7 Lite X64"
echo "3) OneStepFunction"
echo "q) 退出"
echo '----------------------------------'
read -p ":" num
echo '----------------------------------'

case $num in
	1)
		InputHostNameAndUserName

		#30:黑色; 31:红色; 32:绿色; 33:黄色; 34:蓝色; 35:紫色; 36:青色; 37:白色
		#法国（蓝白红）
		setUserColor="export PS1=\"\n\e[1;37m[\e[m\e[1;34m\u\e[m\e[1;30m@\e[m\e[1;31m\H\e[m \e[4m\w\e[m\e[1;37m]\e[m\e[1;36m\e[m\n\$\""

		CentOS
		#setting $osip
		exit
	;;
	2)
		InputHostNameAndUserName
		#法国（蓝白红）
		#30:黑色; 31:红色; 32:绿色; 33:黄色; 34:蓝色; 35:紫色; 36:青色; 37:白色
		setUserColor="export PS1=\"\n\e[1;37m[\e[m\e[1;34m\u\e[m\e[1;30m@\e[m\e[1;31m\H\e[m \e[4m\w\e[m\e[1;37m]\e[m\e[1;36m\e[m\n\$\""

		CentOS_Lite
		exit
	;;
	3)
		InputHostNameAndUserName
		#法国（蓝白红）
		#30:黑色; 31:红色; 32:绿色; 33:黄色; 34:蓝色; 35:紫色; 36:青色; 37:白色
		setUserColor="export PS1=\"\n\e[1;37m[\e[m\e[1;34m\u\e[m\e[1;30m@\e[m\e[1;31m\H\e[m \e[4m\w\e[m\e[1;37m]\e[m\e[1;36m\e[m\n\$\""

		OneStepFunction
		exit
	;;
	q)
		exit
	;;
	*)
		echo '错误的参数'
		exit
	;;
esac
