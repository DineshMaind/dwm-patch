#!/bin/bash

suckless_path=~/Development/suckless
source_dir=$(pwd)
timestamp=$(date +"%Y-%m-%d-%H-%M-%S")
log_file="$source_dir/setup-update-$timestamp.log"

function abort_on_fail() {
	if [ $? -ne 0 ]
	then
		echo "An error occured. Aborting the operation." | tee -a $log_file
		exit -1
	fi
}

function install_package_if_not_installed() {
	local package_name=$1

	if apt list --installed | grep $package_name/stable 1>/dev/null
	then
		echo "Package $package_name already installed." | tee -a $log_file
	else
		sudo apt install $package_name -y
		abort_on_fail

		echo "Package $package_name installed successfully." | tee -a $log_file
	fi
}

function download_and_patch_dwm() {
	local base_path=$1
	local dwm_path=$base_path/dwm

	if [ -d "$dwm_path" ]
	then
		echo "Path $dwm_path already exists. No need to download dwm." | tee -a $log_file
	else
		# Create directory for building
		mkdir -p $base_path
		abort_on_fail

		# Goto the directory
		cd $base_path
		abort_on_fail

		echo "Clone started for repo https://git.suckless.org/dwm." | tee -a $log_file

		# Clone the dwm repository
		git clone https://git.suckless.org/dwm
		abort_on_fail

		echo "Clone completed for repo https://git.suckless.org/dwm." | tee -a $log_file
	fi

	if [ -f "$base_path/patches/dwm-cool-autostart-20240312-9f88553.diff" ]
	then
		echo "Path $base_path/patches/dwm-cool-autostart-20240312-9f88553.diff already exists. No need to patch again." | tee -a $log_file
	else
		# make patches directory
		mkdir -p $base_path/patches
		abort_on_fail

		# goto patches directory
		cd $base_path/patches
		abort_on_fail

		# Download autostart patch
		echo "Downloading patch." | tee -a $log_file
		wget https://dwm.suckless.org/patches/cool_autostart/dwm-cool-autostart-20240312-9f88553.diff | tee -a $log_file
		abort_on_fail

		# Goto dwm directory to apply patch
		cd $dwm_path
		abort_on_fail

		git apply $base_path/patches/dwm-cool-autostart-20240312-9f88553.diff | tee -a $log_file
		abort_on_fail
	fi
}

function install_dwm() {
	local resource_dir=$1
	local base_path=$2
	local desktop_file=dwm.desktop

	# Copying modified file
	echo "Copying config.def.h to DWM directory" | tee -a $log_file
	cp -vf $resource_dir/dwm/config.def.h $base_path/dwm/ | tee -a $log_file

	# Remove config.h file
	cd $base_path/dwm
	rm config.h

	# Perform nano on config.def.h
	# comment out the line of autostart variable containing "st" as we are not autostarting anything for now
	# save change font size from 10pt to 12pt depending on your requirements

	echo "Updating config.def.h file." | tee -a $log_file
	nano -l config.def.h
	abort_on_fail

	# Make and install DWM
	echo "Installing DWM" | tee -a $log_file
	sudo make clean install | tee -a $log_file
	abort_on_fail

	# Creatting desktop file
	echo "Copying $desktop_file to $base_path." | tee -a $log_file
	cd $base_path
	cp -vf $resource_dir/$desktop_file $base_path/$desktop_file | tee -a $log_file

	# Copy desktop file to shared location
	echo "Copying $desktop_file to /usr/share/xsessions directory." | tee -a $log_file
	sudo cp -vf $base_path/$desktop_file /usr/share/xsessions/ | tee -a $log_file
	abort_on_fail

	echo "Copying $resource_dir/dwm-scripts directory to $base_path/dwm-scripts directory." | tee -a $log_file
	cp -rvf $resource_dir/dwm-scripts/ $base_path/dwm-scripts/ | tee -a $log_file
	abort_on_fail

	chmod +x $base_path/dwm-scripts/dwm-* | tee -a $log_file
	abort_on_fail

	echo "Copying $base_path/dwm-scripts files to /usr/local/bin/ directory." | tee -a $log_file

	sudo cp -vf $base_path/dwm-scripts/dwm-* /usr/local/bin/ | tee -a $log_file
	abort_on_fail

	echo "Done." | tee -a $log_file
}

echo "Starting setup" | tee $log_file
echo "Updating package listing" | tee -a $log_file

# Update the package listing
sudo apt update | tee -a $log_file

# Install git if not installed
install_package_if_not_installed git

# Install libx11-dev package to resolve fetal error: X11/Xlib.h: No such file or directory
install_package_if_not_installed libx11-dev

# Install libxft-dev package to reslove fetal error: X11/xft/Xft.h: No such file or directory
install_package_if_not_installed libxft-dev

# Install libxinerama-dev package to reslove fetal error: X11/extensions/Xinerama.h: No such file or directory
install_package_if_not_installed libxinerama-dev

# Install alacritty as terminal
install_package_if_not_installed alacritty

# Install rofi for application search
install_package_if_not_installed rofi

# Install dunst for notification
install_package_if_not_installed dunst

# Install nitrogen for background wallpaper
install_package_if_not_installed nitrogen

# Creating configuration directories
mkdir -p ~/.config/{dunst,rofi}

# Copying dunst configuration
cp -v $(dpkg -L dunst | grep dunstrc) ~/.config/dunst/

# Downloading DWM
download_and_patch_dwm $suckless_path

# Installing DWM
install_dwm $source_dir $suckless_path
