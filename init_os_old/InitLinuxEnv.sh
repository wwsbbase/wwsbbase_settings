#!/bin/bash
#####		一键初始化Linux			 #####
#####		Author:bopy				#####
#####		Update:2018-07-2		#####

########TO DO LIST#############
# 1 防火墙设置
# 2 ubuntu 系统测试
# 3 centos 系统测试
###############################


# 文件夹结构
sambaFolder="/data/"
hubFolder="/data/hub/"
downloadFolder="/data/download/"

wwsbbase_hostname="wwsbbase_defaut"
wwsbbase_username="bopy"
userFolder="/home/${wwsbbase_username}"
operatorFolder="/home/${wwsbbase_username}/download/"

aria2Folder="/etc/aria2/"

setRootColor=""
setUserColor=""
python_lib_path=""
python3_lib_path=""

function BaseSetting()
{
	echo '----------------------------------'
	echo 'BaseSetting begin'
	############# Add User ############
	#sudo adduser bopy
	#sudo passwd bopy
	#sudo visudo

	########## Base Setting ###########
	ChangeHostname
	ChangeConsoleColor

	# 安装字符集
	locale-gen en_US.UTF-8
	echo 'BaseSetting end'
	echo '----------------------------------'
}

function ChangeHostname()
{
	# set host name
	sudo hostnamectl set-hostname $wwsbbase_hostname
	sudo echo "127.0.1.1   ${wwsbbase_hostname}" >> /etc/hosts
}

function ChangeConsoleColor()
{
	# set PS1
	echo $setUserColor >> $userFolder/.bashrc
	sudo echo $setRootColor >> /root/.bashrc
}

function ChangePiSources()
{
	echo '----------------------------------'
	echo 'ChangePiSources begin'
	# backup 
	sudo cp /etc/apt/sources.list /etc/apt/sources.list_back 
	# replace
	sudo sed -i 's#://raspbian.raspberrypi.org#s://mirrors.ustc.edu.cn/raspbian#g' /etc/apt/sources.list
	sudo sed -i 's#://mirrordirector.raspbian.org#s://mirrors.ustc.edu.cn/raspbian#g' /etc/apt/sources.list

	sudo sed -i 's#://archive.raspberrypi.org/debian#s://mirrors.ustc.edu.cn/archive.raspberrypi.org#g' /etc/apt/sources.list.d/raspi.list

	#sudo sed -i 's#://raspbian.raspberrypi.org#s://mirrors.tuna.tsinghua.edu.cn/raspbian#g' /etc/apt/sources.list
	#sudo sed -i 's#://archive.raspberrypi.org/debian#s://mirrors.tuna.tsinghua.edu.cn/raspberrypi#g' /etc/apt/sources.list.d/raspi.list

	# update 
	sudo apt-get update -y
	sudo apt-get upgrade -y
	echo 'ChangePiSources end'
	echo '----------------------------------'
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
	sudo apt-get install -y  git
	sudo apt-get install -y  wget
	sudo apt-get install -y  unzip
	sudo apt-get install -y  screen
	sudo apt-get install -y  dstat
	sudo apt-get install -y  curl
	sudo apt-get install -y  ntpdate
	sudo apt-get install -y  gdisk

	# install for building Vim
	sudo apt-get install -y  gcc
	sudo apt-get install -y  cmake
	sudo apt-get install -y  build-essential

	sudo apt-get install -y  ctags
	sudo apt-get install -y  lua5.1
	sudo apt-get install -y  lua5.1-dev
	sudo apt-get install -y  libncurses5-dev

	# install for build YCM
	sudo apt-get install -y  clang-5.0

	echo 'InstallBaseTools end'
	echo '----------------------------------'
}

function InstallAdvanceTools()
{
	echo '----------------------------------'
	echo 'InstallAdvanceTools begin'

	# file system
	sudo apt-get install -y  xfsprogs

	# install python 
	sudo apt-get install -y  python
	sudo apt-get install -y  python3

	sudo apt-get install -y  python-dev
	sudo apt-get install -y  python3-dev

	sudo apt-get install -y  python-pip
	sudo apt-get install -y  python3-pip

	# Services
	sudo apt-get install -y  samba samba-common-bin
	sudo apt-get install -y  aria2
	sudo apt-get install -y  nginx

	echo 'InstallAdvanceTools end'
	echo '----------------------------------'
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

function BuildVim()
{
	echo '----------------------------------'
	echo 'BuildVim begin'

	# get latest vim src code 
	cd "$operatorFolder"
	git clone https://github.com/vim/vim.git

	cd vim

	git pull
	# clean 
	make distclean  # if you build Vim before
	
	# get python path
	# python_lib_path=$(python -c "from distutils.sysconfig import get_python_lib;import sys; sys.exit(get_python_lib())") 
	#python_lib_path="/usr/lib64/python2.7/config/"
	
	# install
	./configure --with-features=huge \
	--enable-pythoninterp=yes --with-python-config-dir=$python_lib_path \
	--enable-python3interp=yes --with-python3-config-dir=$python3_lib_path \
	--enable-rubyinterp=yes \
	--enable-luainterp=yes \
	--enable-perlinterp=yes \
	--enable-gui=gtk2 \
	--enable-cscope \
	--prefix=/usr/local
	
	make
	sudo make install

	# config
	git clone https://github.com/VundleVim/Vundle.vim.git $userFolder/.vim/bundle/Vundle.vim
	git clone https://github.com/VundleVim/Vundle.vim.git /root/.vim/bundle/Vundle.vim

	# get vimrc
	# cd "${operatorFolder}wwsbbase_settings"
	# cp vimrc $HOME/.vimrc
	sudo cp "${operatorFolder}wwsbbase_settings/vimrc" $userFolder/.vimrc
	sudo cp "${operatorFolder}wwsbbase_settings/vimrc" /root/.vimrc

	echo 'BuildVim end'
	echo '----------------------------------'
}

function BuildYcm()
{
	echo '----------------------------------'
	echo 'BuildYcm begin'

	git clone https://github.com/Valloric/YouCompleteMe.git $userFolder/.vim/bundle/YouCompleteMe
	cd $userFolder/.vim/bundle/YouCompleteMe
	git submodule update --init --recursive
	./install.py --clang-completer

	git clone https://github.com/Valloric/YouCompleteMe.git /root/.vim/bundle/YouCompleteMe
	cd /root/.vim/bundle/YouCompleteMe
	git submodule update --init --recursive
	./install.py --clang-completer

	echo 'BuildYcm end'
	echo '----------------------------------'
}

function InstallZlua()
{
	echo '----------------------------------'
	echo 'InstallZlua begin'
	cd "$operatorFolder"
	git clone https://github.com/skywind3000/z.lua.git

	echo "eval \"\$(lua $operatorFolder/z.lua/z.lua --init bash enhanced once)\"" >> $userFolder/.bashrc
	echo "eval \"\$(lua $operatorFolder/z.lua/z.lua --init bash enhanced once)\"" >> /root/.bashrc

	echo 'InstallZlua end'
	echo '----------------------------------'
}

function InstallSSR()
{
	echo '----------------------------------'
	echo 'InstallSSR begin'
	cd "$operatorFolder"
	git clone https://github.com/SAMZONG/gfwlist2privoxy.git
	cd gfwlist2privoxy/
	sudo mv ssr /usr/local/bin
	sudo chmod u+x /usr/local/bin/ssr
	ssr install
	cd "${operatorFolder}wwsbbase_settings"
	sudo cp "${operatorFolder}wwsbbase_settings/config.json" /usr/local/share/shadowsocksr/config.json

	ssr start

	echo 'InstallSSR end'
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

	sudo chown -R bopy:bopy "$sambaFolder"
	sudo smbpasswd -a bopy

	#设置开机自启动，编辑/etc/rc.local

	#重新启动服务
	sudo /etc/init.d/samba restart

	echo 'SambaService end'
	echo '----------------------------------'
}

function Aria2Service()
{
	echo '----------------------------------'
	echo 'Aria2Service begin'

	if [ ! -d "$downloadFolder" ]; then
		sudo mkdir -p "$downloadFolder"
	fi

	if [ ! -d "$aria2Folder" ]; then
		sudo mkdir -p "$aria2Folder"
	fi

	sudo cp "${operatorFolder}wwsbbase_settings/aria2.conf" "$aria2Folder"
	#sudo cp "${operatorFolder}wwsbbase_settings/aria2.sh" "$aria2Folder"
	sudo cp "${operatorFolder}wwsbbase_settings/aria2.sh" /etc/init.d/

	sudo touch "${aria2Folder}aria2.session"
	#启动服务
	/etc/init.d/aria2.sh start

	#开机启动服务
	#sudo sed -i 'xxxxxx' /etc/rc.local

	echo 'Aria2Service end'
	echo '----------------------------------'
}

function WebService()
{
	echo '----------------------------------'
	echo 'WebService begin'

	#下载 aria2-webui
	cd "$operatorFolder"
	git clone https://github.com/ziahamza/webui-aria2.git

	sudo mv webui-aria2/ /var/www/html/
	sudo chown -R www-data:www-data /var/www/html/webui-aria2/

	#下载 python document
	cd "$operatorFolder"
	wget https://docs.python.org/3/archives/python-3.7.0-docs-html.tar.bz2
	tar -xjvf python-3.7.0-docs-html.tar.bz2
	
	sudo mv python-3.7.0-docs-html/ /var/www/html/
	sudo chown -R www-data:www-data /var/www/html/python-3.7.0-docs-html/

	sudo /etc/init.d/nginx start
	echo 'WebService end'
	echo '----------------------------------'
}

function FtpService()
{
	echo '----------------------------------'
	echo 'FtpService begin'
	sudo apt-get install vsftpd
	sudo vim /etc/vsftpd.conf
	sudo service vsftpd restart

	echo 'FtpService end'
	echo '----------------------------------'
}

function SetFirewall()
{
	echo '----------------------------------'
	echo 'SetFirewall begin'
	if [ -e "/etc/sysconfig/iptables" ]
	then
		# 允许访问22端口(SSH)
		iptables -A INPUT -p tcp --dport 22 -j ACCEPT
		#允许访问80端口(HTTP)
		iptables -A INPUT -p tcp --dport 80 -j ACCEPT
		#允许访问443端口(HTTPS)
		iptables -A INPUT -p tcp --dport 443 -j ACCEPT
		#允许访问445端口(SAMBA)
		iptables -A INPUT -p tcp --dport 445 -j ACCEPT
		iptables -A INPUT -p tcp --dport 139 -j ACCEPT
		iptables -A INPUT -p udp --dport 137 -j ACCEPT
		iptables -A INPUT -p udp --dport 138 -j ACCEPT


		#允许访问6800端口（ARIA2）
		iptables -I INPUT -p tcp --dport 6800 -j ACCEPT
		# aria2 bt
		iptables -I INPUT -p tcp --dport 58621 -j ACCEPT

		# remote debug
		iptables -I INPUT -p tcp --dport 18110 -j ACCEPT

		iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT

		
		service iptables save
		service iptables restart
	else
		firewall-cmd --zone=public --add-port=6080/tcp --permanent
		firewall-cmd --zone=public --add-port=6800/tcp --permanent
		firewall-cmd --zone=public --add-port=51413/tcp --permanent
		firewall-cmd --reload
	fi
	echo 'SetFirewall end'
	echo '----------------------------------'
}

function MountDisks()
{
	echo '----------------------------------'
	echo 'MountDisks begin'
	if [ ! -d "$downloadFolder" ]; then
		sudo mkdir -p "$downloadFolder"
	fi

	if [ ! -d "${hubFolder}" ]; then
		sudo mkdir -p "$hubFolder"
	fi

	if [ ! -d "${hubFolder}disk4ta" ]; then
		sudo mkdir -p "${hubFolder}disk4ta"
	fi

	if [ ! -d "${hubFolder}disk4tb" ]; then
		sudo mkdir -p "${hubFolder}disk4tb"
	fi

	if [ ! -d "${hubFolder}disk256" ]; then
		sudo mkdir -p "${hubFolder}disk256"
	fi

	# 手动挂载
	sudo mount -t xfs /dev/sda1 "$downloadFolder"
	sudo mount -t xfs /dev/sdb1 "${hubFolder}disk256"
	sudo mount -t xfs /dev/sdc1 "${hubFolder}disk4ta"
	sudo mount -t xfs /dev/sdd1 "${hubFolder}disk4tb"

	# 手动卸载
	sudo umount "${hubFolder}disk4ta"
	sudo umount "${hubFolder}disk4ta"
	sudo umount "${hubFolder}disk256"
	sudo umount "${downloadFolder}"

	# 开机自动挂载
	# sudo echo "UUID=36bd26e6-4a05-44da-8113-922d1622aa59   /data/download  xfs defaults,noatime    0   0" >> /etc/fstab
	# sudo echo "UUID=8c97abd5-5354-4d53-bf05-22aec040699f   /data/hub/disk256   xfs defaults,noatime    0   0" >> /etc/fstab
	# sudo echo "UUID=3cf9ed94-a879-42b5-b3c5-489283cd7b34   /data/hub/disk4ta   xfs defaults,noatime    0   0" >> /etc/fstab
	# sudo echo "UUID=fa578443-441b-42a8-af42-9e86338a0f6a   /data/hub/disk4tb   xfs defaults,noatime    0   0" >> /etc/fstab
	# sudo echo "UUID=25014b55-b579-4fbf-9fd3-aa0c69315cbd   /data/hub/disk1t    xfs defaults,noatime    0   0" >> /etc/fstab
	# sudo echo "UUID=c18e0264-3680-40f3-9efd-a122c392a557   /data/hub/disk160    xfs defaults,noatime    0   0" >> /etc/fstab

	#UUID=36bd26e6-4a05-44da-8113-922d1622aa59	/data/download	xfs	defaults,noatime	0	0
	#UUID=8c97abd5-5354-4d53-bf05-22aec040699f	/data/hub/disk256	xfs	defaults,noatime	0	0
	#UUID=3cf9ed94-a879-42b5-b3c5-489283cd7b34	/data/hub/disk4ta	xfs	defaults,noatime	0	0
	#UUID=fa578443-441b-42a8-af42-9e86338a0f6a	/data/hub/disk4tb	xfs	defaults,noatime	0	0
	#UUID=25014b55-b579-4fbf-9fd3-aa0c69315cbd	/data/hub/disk1t	xfs	defaults,noatime	0	0
	#UUID=c18e0264-3680-40f3-9efd-a122c392a557	/data/hub/disk160	xfs	defaults,noatime	0	0

	echo 'MountDisks end'
	echo '----------------------------------'
}

function InstallDB()
{
	sudo apt-get install mysql-server
	sudo mysql -u root
}

function BuildSwap()
{
	sudo dd if=/dev/zero of=/var/swap bs=1G count=8
	sudo mkswap /var/swap
	sudo echo "/var/swap swap  swap defaults    0   0" >> /etc/fstab
}

function UserSetting()
{
	echo '########## UserSetting ##########'
}

function Ubuntu()
{
	echo '########## Ubuntu ##########'
	########## BaseSetting ###########
	BaseSetting
	InstallTools
	FetchConfigs
	############## SSR ################
	InstallSSR
	############## Vim ################
	BuildVim
	BuildYcm
	######### UserSetting #############
	UserSetting
	InstallZlua
}

function Debian()
{
	echo '########## Debian ##########'
	########## Setting ###########
	#BaseSetting
	InstallTools
	FetchConfigs
	############## Vim ################
	#BuildVim

}

function Raspberry()
{
	echo '########## Raspberry ##########'
	########## Setting ###########
	BaseSetting
	ChangePiSources
	InstallTools
	FetchConfigs
	############## Vim ################
	BuildVim
	BuildYcm
	############## Tools ################
	InstallZlua
	############## Service ################
	SambaService
	Aria2Service

	#SetFirewall

	MountDisks
}

function CentOS()
{
	echo '########## CentOS ##########'
	yum install -y git
	yum install -y screen
	yum install -y ctags
	yum install -y ncurses
	yum install -y ncurses-libs
	yum install -y ncurses-devel

}

function Vps4Gfw()
{
	echo '########## Vps4Gfw ##########'
	########## BaseSetting ###########
	ChangeConsoleColor
	InstallBaseTools
	FetchConfigs
	############## Vim ################
	BuildVim
	BuildYcm
	######### UserSetting #############
	UserSetting
	InstallZlua	
}

function OneStepFunction()
{
	echo '########## OneStepFunction ##########'
	InstallZlua
}


echo '#####		欢迎使用一键初始化Linux脚本^_^	#####'
echo '#####									  #####'
echo '#####		请使用 普通账号的sudo 进行初始化!!!	#####'
echo '#####		请使用 普通账号的sudo 进行初始化!!!	#####'
echo '#####		请使用 普通账号的sudo 进行初始化!!!	#####'
echo '#####									  #####'
echo '---------------------------------------------'
echo '请选择系统:'
echo "1) CentOS 7 X64"
echo "2) Ubuntu 18+ X64"
echo "3) Raspberry "
echo "4) VPS_GCP"
echo "5) OneStepFunction"
echo "q) 退出"
echo '----------------------------------'
read -p ":" num
echo '----------------------------------'

case $num in
	1)
		wwsbbase_username="bopy"
		wwsbbase_hostname="wwsbbase_hk"
		userFolder="/home/${wwsbbase_username}"
		operatorFolder="/home/${wwsbbase_username}/download/"
		
		#30:黑色; 31:红色; 32:绿色; 33:黄色; 34:蓝色; 35:紫色; 36:青色; 37:白色
		#法国（蓝白红）
		setRootColor="export PS1=\"\n\e[1;37m[\e[m\e[1;34m\u\e[m\e[1;37m@\e[m\e[1;31m\H\e[m \e[4m\w\e[m\e[1;37m]\e[m\e[1;36m\e[m\n\$\""
		setUserColor="export PS1=\"\n\e[1;37m[\e[m\e[1;34m\u\e[m\e[1;30m@\e[m\e[1;31m\H\e[m \e[4m\w\e[m\e[1;37m]\e[m\e[1;36m\e[m\n\$\""
		
		python_lib_path=$(python -c "from distutils.sysconfig import get_python_lib;import sys; sys.exit(get_python_lib())") 
		python3_lib_path=$(python3 -c "from distutils.sysconfig import get_python_lib;import sys; sys.exit(get_python_lib())") 
		
		CentOS
		#设置
		#setting $osip
		exit
	;;
	2)
		wwsbbase_username="ubuntu"
		wwsbbase_hostname="wwsbbase_cd"
		userFolder="/home/${wwsbbase_username}"
		operatorFolder="/home/${wwsbbase_username}/download/"

		#30:黑色; 31:红色; 32:绿色; 33:黄色; 34:蓝色; 35:紫色; 36:青色; 37:白色
		#法国（蓝白红）
		setRootColor="export PS1=\"\n\e[1;37m[\e[m\e[1;34m\u\e[m\e[1;37m@\e[m\e[1;31m\H\e[m \e[4m\w\e[m\e[1;37m]\e[m\e[1;36m\e[m\n\$\""
		setUserColor="export PS1=\"\n\e[1;37m[\e[m\e[1;34m\u\e[m\e[1;30m@\e[m\e[1;31m\H\e[m \e[4m\w\e[m\e[1;37m]\e[m\e[1;36m\e[m\n\$\""

		# python_lib_path=$(python -c "from distutils.sysconfig import get_python_lib;import sys; sys.exit(get_python_lib())") 
		# python3_lib_path=$(python3 -c "from distutils.sysconfig import get_python_lib;import sys; sys.exit(get_python_lib())") 
		python_lib_path=/usr/local/lib/python2.7/dist-packages
		python3_lib_path=/usr/local/lib/python3.5/dist-packages


		python_lib_path=/usr/lib/python2.7/config-x86_64-linux-gnu
		python3_lib_path=/usr/lib/python3.5/config-3.5m-x86_64-linux-gnu


		Ubuntu
		#setting $osip
		exit
	;;
	3)
		wwsbbase_username="bopy"
		wwsbbase_hostname="wwsbbase_Raspberry"
		userFolder="/home/${wwsbbase_username}"
		operatorFolder="/home/${wwsbbase_username}/download/"
		#30:黑色; 31:红色; 32:绿色; 33:黄色; 34:蓝色; 35:紫色; 36:青色; 37:白色
		#树莓派 （红白绿）
		setRootColor="export PS1=\"\n\e[1;37m[\e[m\e[1;31m\u\e[m\e[1;37m@\e[m\e[1;32m\H\e[m \e[4m\w\e[m\e[1;37m]\e[m\e[1;36m\e[m\n\$\""
		setUserColor="export PS1=\"\n\e[1;37m[\e[m\e[1;31m\u\e[m\e[1;30m@\e[m\e[1;32m\H\e[m \e[4m\w\e[m\e[1;37m]\e[m\e[1;36m\e[m\n\$\""

		python_lib_path=$(python -c "from distutils.sysconfig import get_python_lib;import sys; sys.exit(get_python_lib())") 
		python3_lib_path=$(python3 -c "from distutils.sysconfig import get_python_lib;import sys; sys.exit(get_python_lib())") 
		Raspberry
		exit
	;;
	4)
		wwsbbase_username="bopy_aaron"
		userFolder="/home/${wwsbbase_username}"
		operatorFolder="/home/${wwsbbase_username}/download/"
		#法国（蓝白红）
		#30:黑色; 31:红色; 32:绿色; 33:黄色; 34:蓝色; 35:紫色; 36:青色; 37:白色
		setRootColor="export PS1=\"\n\e[1;37m[\e[m\e[1;34m\u\e[m\e[1;37m@\e[m\e[1;31m\H\e[m \e[4m\w\e[m\e[1;37m]\e[m\e[1;36m\e[m\n\$\""
		setUserColor="export PS1=\"\n\e[1;37m[\e[m\e[1;34m\u\e[m\e[1;30m@\e[m\e[1;31m\H\e[m \e[4m\w\e[m\e[1;37m]\e[m\e[1;36m\e[m\n\$\""

		Vps4Gfw
		exit
	;;
	5)
		wwsbbase_username="ubuntu"
		wwsbbase_hostname="wwsbbase_cd"
		userFolder="/home/${wwsbbase_username}"
		operatorFolder="/home/${wwsbbase_username}/download/"
		#法国（蓝白红）
		#30:黑色; 31:红色; 32:绿色; 33:黄色; 34:蓝色; 35:紫色; 36:青色; 37:白色
		setRootColor="export PS1=\"\n\e[1;37m[\e[m\e[1;34m\u\e[m\e[1;37m@\e[m\e[1;31m\H\e[m \e[4m\w\e[m\e[1;37m]\e[m\e[1;36m\e[m\n\$\""
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