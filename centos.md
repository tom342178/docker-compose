# Install Centos

## Requirements
1. [Download CentOS](https://www.centos.org/download/)
2. [Download & Install VirtualBox](https://www.virtualbox.org/wiki/Downloads)
3. [Install CentOS on VM](https://medium.com/@selvarajk/centos-linux-installation-in-virtualbox-719086f37e22)

## Prepare Machine
0. Update / Upgrade 
```shell
sudo yum -y update
sudo yum -y upgrade
```

1. Install openssh-server
```shell 
sudo yum -y openssh-server
```

2. Enable openssh
```
sudo systemctl start sshd
sudo systemctl enable sshd
```

3. CentOS comes pre-defined with firewalls, as such users need to grant SSH permission
```shell
# check firwall rules
sudo firewall-cmd --list-all

# Open Port for SSH 
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --reload
```

4. Validate ssh port 22 is open
```shellsudo netstat -tuln | grep 22
sudo netstat -tuln | grep 22
```

5. update `/etc/ssh/sshd_config` with the following params
```config
Port 22
# allow for root user access
PermitRootLogin yes
PasswordAuthentication yes
```

6. Reload sshd
```shell
sudo systemctl restart sshd
```

## Install Docker
1. Install Dependencies
   * curl 
   * wget 
   * yum-utils 
   * device-mapper-persistent-data 
   * lvm2
```shell
sudo yum install -y curl wget make git yum-utils device-mapper-persistent-data lvm2 
```

2. Manually Download [rpm packages](https://download.docker.com/linux/centos/)
```shell
mkdir rpm-pkgs ; cd rpm-pkgs
curl https://download.docker.com/linux/centos/9/x86_64/stable/Packages/docker-ce-27.2.1-1.el9.x86_64.rpm -o docker-ce.rpm 
curl https://download.docker.com/linux/centos/9/x86_64/stable/Packages/docker-ce-cli-27.2.1-1.el9.x86_64.rpm -o docker-ce-cli.rpm
curl https://download.docker.com/linux/centos/9/x86_64/stable/Packages/containerd.io-1.7.22-3.1.el9.x86_64.rpm -o containerd.io.rpm 
```

3. Install rpms
```shell 
sudo yum -y install ./docker-ce.rpm
sudo yum -y install ./docker-ce-cli.rpm
sudo yum -y install ./containerd.io.rpm
```

4. Enable Docker
```shell
sudo systemctl start docker
sudo systemctl enable docker
```
