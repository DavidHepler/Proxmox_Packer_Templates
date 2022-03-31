Pre-requirements:
You need to have a working Proxmox environment
You need to have Packer installed.

Linux:
'# (1) Ensure that your system is up to date, and you have the gnupg, software-properties-common, and curl packages installed
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
'# (2) Add the HashiCorp GPG key.
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
'# (3) Add the official HashiCorp Linux repository.
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
'# (4) Update to add repo and install packer
sudo apt-get update && sudo apt-get install packer

MacOS
brew tap hashicorp/tap
brew install hashicorp/tap/packer
