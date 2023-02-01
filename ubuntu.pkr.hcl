###################################################################################################
# ubuntu.pkr.hcl
#   ** To use HCL instead of JSON you need to use the extention pkr.hcl
#
# This is a packer build file to create a template running kubernetes
# on Ubuntu 18.04.
# 
# I will not add the CNI, or kubeadm, kubectl, kubelet as
# I don't want to tie this template to any one verions of kubernetes.
# 
# This is to see if I like HCL better than JSON.
# Comments are a nice addition.
#
# By: Scott Watson
# Date: 09-04-2020
#
# Vars.
#  password = this is the password for the k8s user that is created
#
#
# Build Command : packer build -var 'password=XXXXXXX' ubuntu.pkr.hcl
#    with debug : packer build -force -debug -on-error=ask -var 'password=XXXXXXX'  ubuntu.pkr.hcl
###################################################################################################

###
# Enable logging
# set these variables before running the packer build command.
# export PACKER_LOG=1
# export PACKER_LOG_PATH="packerlog.txt"

# Things that don't work or I have not figured out how to get to work
# 1. Have packer connect via ssh using the ephemeral ssh key
#    The public key is in PACKER_AUTHORIZED_KEY={{ .SSHPublicKey | urlquery }} 
#    However the private key is not set anywhere that I can find.
#    There was a reference in the debug output to a pem file but I couldn't find
#    it and infact packer said it was not found.
#    when you set debug mode the private key is writted to packer-<user>.pem
#
#    so it looks like the contents are in the variable build.SSHPublicKey and build.SSHPrivateKey
#    template variables. I'm just not sure how to use them properly.
#
#    I think I found it...
//
// changing the username will mess up the preseed commands.
// d-i preseed/late_command string \
//     in-target mkdir -p /home/<user>/.ssh; \
//     in-target /bin/sh -c "echo $PACKER_AUTHORIZED_KEY >> /home/<user>/.ssh/authorized_keys"; \
//     in-target chown -R <user>:<user> /home/<user>/;
//
// in boot command " PACKER_AUTHORIZED_KEY=\"{{ .SSHPublicKey }}\"<wait>",
#
# 2. Use ansible to configure the VM.
#    will use shell scripts for now




# NOTE :  Packer does not work with live images therefore you need to
#         download the non live image from http://cdimage.ubuntu.com/ubuntu/releases/18.04/release/
#         SEE: https://github.com/geerlingguy/packer-ubuntu-1804/issues/7
#

# Working with a pressed config file
# Preeseed:  https://help.ubuntu.com/lts/installation-guide/amd64/apbs04.html
#

# to be used later if I want to start to get fancy 
# figuring out IP addresses etc.
#
variable "hostnetwork" {
  type = map(string)
  default = {
    "vboxnet0" = "192.168.56.1"
    "vboxnet1" = "192.168.57.1"
    "vboxnet2" = "192.168.58.1"
  }
}

variable "user"     { default = "k8s" }
variable "password" { type = string }
variable "hostnet"  { default = "vboxnet1" }
variable "iso"      { default = "/Users/scottwatson/Documents/ISO/ubuntu-18.04.5-server-amd64.iso" }
variable "checksum" { default = "md5:a3e1c494a02abf1249749fa4fd386438" }
variable "vm_name"  { default = "k8s" }
variable "domain"   { default = "home.lab" }

# Functions.  https://www.packer.io/docs/from-1.5/functions/collection/lookup
locals {
   ip = "${lookup(var.hostnetwork, var.hostnet, "notfound" )}"
}


source "virtualbox-iso" "ubuntu-k8s" {
    # Check what vbox supports with VBoxManage list ostypes | grep -i ubuntu
    guest_os_type = "Ubuntu_64"

    # we are going to consume this vm so don't bother exporting it
    skip_export = "true"

    # ISO
    iso_url = "file:${var.iso}"
    iso_checksum = "${var.checksum}"

    # User to be created.  
    ssh_username = "${var.user}"
    ssh_password = "${var.password}"
    ssh_timeout  = "10m"

    shutdown_command = "echo '${var.password}' | sudo -S shutdown -P now"
    
    #Hardware
    hard_drive_interface = "sata"
    disk_size = "20000"
    cpus = "2"
    memory = "2048"
    sound = "none"
    usb = "false"

    vboxmanage = [
      ["modifyvm", "{{ .Name }}", "--nic1", "nat" ],
      ["modifyvm", "{{ .Name }}", "--vram", "16" ]
    ]

    // # add the extra nic once the machine is shutdown since
    // # I don't know how to configure multiple nics in preseed.
   
    // this is actually a problem as I cannot add the static IP to the nic
    // move this to a shell-local to call this.
    // vboxmanage_post = [
    //   [ "modifyvm", "{{ .Name }}", "--nic2", "hostonly" ],
    //   [ "modifyvm", "{{ .Name }}", "--hostonlyadapter2", "vboxnet1" ]
    // ]

    vm_name = "${var.vm_name}"
    # the guest addition will be uploaded to the user's home directory

    # http server to seed our build
    http_directory = "http"

    #don't show the gui with the concole while this is being built.
    headless = "false"
    keep_registered = "true"
    virtualbox_version_file = ".vbox_version"

    boot_command = [
        "<esc><wait>",
        "<esc><wait>",
        "<enter><wait>",
        "/install/vmlinuz",
        " initrd=/install/initrd.gz",
        " auto=true",
        " priority=critical",
        " url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
        " passwd/user-fullname=${var.user} ",
        " passwd/user-password=${var.password} ",
        " passwd/user-password-again=${var.password} ",
        " passwd/username=${var.user} ",
        " hostname={{ .Name }} ",
        " domain=${var.domain} ",
# This was a feable attempt at injecting the public key into the VM. 
# maybe i need something like d-i network-console/authorized_keys_url string http://{{ .HTTPIP }}:{{ .HTTPPort }}/openssh-key        
#        " PACKER_USER=${var.user} ",
#        " PACKER_AUTHORIZED_KEY={{ .SSHPublicKey | urlquery }} ",
        "<enter>"
    ]
}

build {
  name = "K8S on Ubuntu"
  sources = ["sources.virtualbox-iso.ubuntu-k8s"]

  provisioner "shell-local" {
    inline = ["echo Stopping the VM",
     "vboxmanage controlvm ${var.vm_name} acpipowerbutton",
     "sleep 15",
     "echo Adding 2nd nic with VBOXManage",
     "vboxmanage modifyvm ${var.vm_name} --nic2 hostonly",
     "vboxmanage modifyvm ${var.vm_name} --hostonlyadapter2 vboxnet1", 
     "echo Starting the VM",
     "vboxmanage startvm ${var.vm_name}",
     "sleep 30"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "SSH_USER=${var.user}",
      "DEBIAN_FRONTEND=noninteractive"
    ]
    expect_disconnect = "true"
    execute_command = "echo '${var.password}'|{{.Vars}} sudo -E -S bash '{{.Path}}'"
    scripts = [
      "./scripts/upgrade_kernel.sh",
      "./scripts/add_staticip.sh",
      "./scripts/install_guestadditions.sh",
      "./scripts/install_docker.sh",
      "./scripts/add_k8s_dependencies.sh"
      "./scripts/update_system.sh",
    ]
  }


  // provisioner "ansible" {
  //   ansible_env_vars = [ "ANSIBLE_HOST_KEY_CHECKING=False", "ANSIBLE_SSH_ARGS='-o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s'", "ANSIBLE_NOCOLOR=False" ]

  //   playbook_file   = "./ansible/playbook.yml"

  //   #extra_arguments = ["--extra-vars", "\"pizza_toppings=${var.topping}\""]
  // }
}