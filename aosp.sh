#!/bin/bash

#1 which rom
#2 branch
pkg_list_str=""
c_dir=$(pwd)

android_env_setup(){
	# pre tool

  lsb_os=$(lsb_release -d | cut -d ':' -f 2 | sed -e 's/^[[:space:]]*//')
  if [[ ${lsb_os} =~ "Ubuntu" ]];then
     sudo apt install curl git android-platform-tools-base python -y
  elif [[ ${lsb_os} =~ "Manjaro" ]];then
     sudo pacman -Sy curl git
  fi

	#git config
	if [[ $(git config user.name) == "" ]] || [[ $(git config user.email) == "" ]];then
		echo -e "\n==> Config git "
	fi
	if [[ $(git config user.name) == "" ]];then
		read -p 'Your name: ' git_name
		git config --global user.name "${git_name}"
	fi

	if [[ $(git config user.email) == "" ]];then
    read -p 'Your email: ' git_email
    git config --global user.email "${git_email}"
  fi

	#repo & adb path
	if [[ $(grep 'add Android SDK platform' -ns $HOME/.bashrc) == "" ]];then
		sed -i '$a \
# add Android SDK platform tools to path \
if [ -d "$HOME/platform-tools" ] ; then \
 PATH="$HOME/platform-tools:$PATH" \
fi' $HOME/.bashrc
	fi

	if [[ $(grep 'set PATH so it includes user' -ns $HOME/.bashrc) == "" ]];then
		sed -i '$a \
# set PATH so it includes user private bin if it exists \
if [ -d "$HOME/bin" ] ; then \
    PATH="$HOME/bin:$PATH" \
fi' $HOME/.bashrc
        fi

	#repo setup
	mkdir -p $HOME/bin
	if [[ ! -f $HOME/bin/repo ]];then
		curl https://mirrors.tuna.tsinghua.edu.cn/git/git-repo -o $HOME/bin/repo
	fi
	sudo chmod a+x ~/bin/repo
	chmod a+x ~/bin/repo

	#android env from pixelexperience wiki
	cd ~/
	if [[ ! -f scripts/setup/android_build_env.sh ]];then
		git clone https://github.com/akhilnarang/scripts
	fi
	cd scripts
	if [[ ${lsb_os} =~ "Ubuntu" ]];then
     ./setup/android_build_env.sh
  elif [[ ${lsb_os} =~ "Manjaro" ]];then
     ./setup/arch-manjaro.sh
  fi

	# ssh
	ssh_enlong_patch

	#ccache fix
	ccache_fix

	cd $c_dir
	source $HOME/.bashrc
}

pixelexperience_sync(){
	mkdir -p android/pe

	pixelexperience_json="$(dirname $0)/pixelexperience.json"
	if [[ ! -f $pixelexperience_json ]];then
		curl https://api.github.com/repos/PixelExperience/manifest/branches -o $pixelexperience_json
	fi
	pe_branches=($(cat $pixelexperience_json | grep name | sed 's/"name"://g' | sed 's/"//g' | tr "," " "))
	echo "Which branch you wanna sync ?"
	select pe_branch in "${pe_branches[@]}"
	do
		cd android/pe
		if [[ ! -d .repo ]];then
			repo init -u https://github.com/PixelExperience/manifest -b $pe_branch
		fi
		repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
		break
	done
	cd $c_dir
}

pixelplusui_sync(){
	mkdir -p WORKSPACE

	ppui_json="$(dirname $0)/ppui.json"
	if [[ ! -f $ppui_json ]];then
		curl https://api.github.com/repos/PixelPlusui/manifest/branches -o $ppui_json
	fi
	ppui_branches=($(cat $ppui_json | grep name | sed 's/"name"://g' | sed 's/"//g' | tr "," " "))
	select ppui_branch in "${ppui_branches[@]}"
	do
		cd WORKSPACE
		if [[ ! -d .repo ]];then
			repo init -u https://github.com/PixelPlusUI/manifest -b tiramisu
		fi
		repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
		break
	done
	cd $c_dir
}

use_git_aosp_mirror(){
	if [[ -f aosp-setup/helper.sh ]];then
		helper_tg=aosp-setup/helper.sh
	elif [[ -f helper.sh ]];then
		helper_tg=helper.sh
	else
		helper_tg=''
	fi
	source $helper_tg
}

ssh_enlong_patch(){
	sudo sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 30/g' /etc/ssh/sshd_config
	sudo sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 86400/g' /etc/ssh/sshd_config
	sudo systemctl restart sshd
}

ccache_fix(){
		# Custom Ccache
	custom_ccache_dir=

	if [[ ! $(grep 'Generated ccache config' $HOME/.bashrc) ]];then
		default_ccache_dir=/home/$USER/.aosp_ccache
		if [[ $custom_ccache_dir == "" ]];then
			custom_ccache_dir=$default_ccache_dir
		fi
		mkdir -p $custom_ccache_dir
		sudo mount --bind /home/$USER/.ccache $custom_ccache_dir
		sudo chmod -R 777 $custom_ccache_dir

		echo '''
# Generated ccache config
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR='"$custom_ccache_dir"'
ccache -M 50G -F 0''' | tee -a $HOME/.bashrc
	fi
}

git_mirror_reset(){
	git_name=$(git config --global user.name)
	git_email=$(git config --global user.email)
	rm -f $HOME/.gitconfig
	git config --global user.name "${git_name}"
	git config --global user.email "${git_email}"
}

handle_main(){
	#for aosp | git mirrors
	echo "Do you wanna use git & AOSP mirror ?"
	select use_mirror_sel in "Yes" "No"
	do
		case $use_mirror_sel in
			"Yes")
				use_git_aosp_mirror
				;;
			"No")
				git_mirror_reset
				;;
			*)
				echo -e "==> Skip use mirror\n"
				;;
		esac
		break
	done

	#android environment setup
	android_env_setup

	#handle aosp source
	echo "Which ROM source do you wann sync ?"
	select aosp_source in "Pixel Experience" "PixelPlusUI"
	do
		case $aosp_source in
			"Pixel Experience")
				pixelexperience_sync
				;;
			"PixelPlusUI")
				pixelplusui_sync
				;;
			*)
				echo 'ROM source not added crrently'
				exit 1
				;;
		esac
		break
	done
}

handle_main