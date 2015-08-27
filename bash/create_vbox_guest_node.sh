#!/bin/bash
# create_vbox_guest_node.sh
# Ryan C. Moon
# 2015-08-26
# Creates a virtualbox guest client using the following parameters..

VBOXMANAGE_COMMAND=$(which vboxmanage)
VM_GUEST_IMAGE_DIRECTORY="/data/VMs"
VM_GUEST_STORAGE_DIRECTORY="/data/VMs/harddrive_images/"
OS_ISO_FILENAME="/ISOs/ubuntu-14.04.3-server-amd64.iso"
GUEST_NAME=""
GUEST_OS_TYPE="Ubuntu_64"		# run `vboxmanage list ostypes` for alternatives, make sure you enable VT-x on your bios for 64-bit OS guests.
GUEST_HD_SIZE="20000"   # specified in MB
GUEST_RAM_SIZE="4096"		# specified in MB
GUEST_VRAM_SIZE="128"		# specified in MB, max 128
BRIDGE_ADAPTER="em1"		# interface to bridge to connect to the network
GUEST_ADAPTER_MAC_ADDR=""	# so you can pin dhcp or tcpdump as necessary. 
#x2:xx:xx:xx:xx:xx is IEEE 802 compliant for locally administered ranges.
#00:50:56:00:00:00 for VMWare carved out IEEE 802 ranges.

if [ ! -e $VBOXMANAGE_COMMAND ]; then
	echo "[\!] vboxmanage command does not exist in current path. Did you install virtualbox correctly?"
	exit 1
fi

if [ ! -e $VM_GUEST_IMAGE_DIRECTORY ]; then
	echo "[\!] Referenced VM Guest directory does not exist. Creating.."
	mkdir -p $VM_GUEST_IMAGE_DIRECTORY
	chmod 750 $VM_GUEST_IMAGE_DIRECTORY
fi

if [ ! -e $VM_GUEST_STORAGE_DIRECTORY ]; then
	echo "[\!] Referenced VM Guest Storage directory does not exist. Creating.."
	mkdir -p $VM_GUEST_STORAGE_DIRECTORY
	chmod 750 $VM_GUEST_STORAGE_DIRECTORY
fi

if [ ! -e $OS_ISO_FILENAME ]; then
	echo "[\!] Referenced OS ISO does not exist. Exiting.."
	exit 1
fi

echo "[.] Moving to our VM working directory.."
cd $VM_GUEST_IMAGE_DIRECTORY

echo "[+] Create our VM and register it.."
$VBOXMANAGE_COMMAND createvm --name $GUEST_NAME --register

echo "[+] Create our virtual hard drive and attach it.."
$VBOXMANAGE_COMMAND createhd --filename "$VM_GUEST_STORAGE_DIRECTORY/$GUEST_NAME.vdi" --size $GUEST_HD_SIZE

echo "[.] Set our guest parameters and attach it to the bridged adapter (MAKE SURE TO UPDATE IPTABLES).."
$VBOXMANAGE_COMMAND modifyvm $GUEST_NAME --ostype $GUEST_OS_TYPE --memory $GUEST_RAM_SIZE --vram $GUEST_VRAM_SIZE --cpus 1 --accelerate3d off --nic1 bridged --bridgeadapter1 $BRIDGE_ADAPTER --macaddress1 "$GUEST_ADAPTER_MAC_ADDR" --vrde on

echo "[+] Create our storage controller and attach our virtual hard drive.."
$VBOXMANAGE_COMMAND storagectl $GUEST_NAME --name "SATA Controller" --add sata --portcount 1 --bootable on
$VBOXMANAGE_COMMAND storageattach $GUEST_NAME --storagectl "SATA Controller" --device 0 --port 0 --type hdd --medium $VM_GUEST_STORAGE_DIRECTORY/$GUEST_NAME.vdi

echo "[+] Create our IDE controller (for iso/fake cdrom) and attach our image to it.."
$VBOXMANAGE_COMMAND storagectl $GUEST_NAME --name "IDE Controller" --add ide
$VBOXMANAGE_COMMAND storageattach $GUEST_NAME --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium $OS_ISO_FILENAME

echo "[.] New VM guest is created and registered. Information: "
echo "Type '$VBOXMANAGE_COMMAND showvminfo $GUEST_NAME' to view your vm information.."
echo "Type '$VBOXMANAGE_COMMAND startvm \"$GUEST_NAME\" --type headless' to start your vm.."
