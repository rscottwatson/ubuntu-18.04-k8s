# Packer/Ubuntu/Kubernetes/VirtualBox

Simple packer build for Ubuntu 18.04 to create a template to be used for setting up a local Kubernetes cluster

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

1. Install packer         -- This was done with version 1.62
2. Install virtual box    -- This was done with 6.1.12
3. Clone this repo

Install prereqs on a MAC
```
brew install packer 
https://www.virtualbox.org/wiki/Downloads
```

### Installing

Just clone the repo and run the following

packer build -var 'password=XXXXXXX' ubuntu.pkr.hcl

Changing the password for the password for the k8s user.

From here you can clone your VM using a linked clone to start creating a kubernetes cluster.
I will work on some ansible scripts to do that



## Authors

* **Scott Watson** - *Initial work* 

## Acknowledgments

* Google searches
* Stack Overflow
* https://github.com/geerlingguy/packer-boxes
* For the GIT ReadMe template https://gist.github.com/PurpleBooth/109311bb0361f32d87a2