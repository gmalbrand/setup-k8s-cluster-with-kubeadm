# Setup a Kubernetes cluster with kubeadm

This will guide you through the configuration steps of setting up a K8s cluster.
This has been tested with EC2 instances running Debian 10.

## Prepare instances

The following steps must be applied on every instance of the cluster

### Install dependencides
```
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https
```


### Loading modules for containerd

First create a containerd.conf file to load modules at startup.

```
{
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
}
```

Load the module without having to restart the instance
```
sudo modprobe overlay
sudo modprobe br_netfilter
```

### Configure networking options

```
{
cat << EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
}
```
Apply changes
```
sudo sysctl --system
```


### Set swap off
```
sudo swapoff -a
```

Also check in fstab that there is no default mounting of swap partition.

## Install containerd

Here I am using the containerd.io package including with Docker.
This steps are taken from [Docker installation guide](https://docs.docker.com/engine/install/debian/).

### Add GPG key
```
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

### Add docker repo to apt source
```
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Install containerd.io package
```
sudo apt-get update
sudo apt-get install -y containerd.io
```

### Create containerd configuration

```
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
```
Restart containerd to apply changes.
```
sudo systemctl restart containerd
```

## Install kubernetes tools

### Add GPG keys
```
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg \
 https://packages.cloud.google.com/apt/doc/apt-key.gpg
```

### Add repo to apt sources
```
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
 https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

### Install K8s tools

I am using version 1.23.0 to match the version of the Kubernetes Administration
Certification course.

```
sudo apt-get update
sudo apt-get install -y kubelet=1.23.0-00 kubeadm=1.23.0-00 kubectl=1.23.0-00
```

If you don't want to unexpectedly update k8s tools mark them on old in apt.

```
sudo apt-mark hold kubelet kubeadm kubectl
```

# Set up the control plane

## Initialise the controller

You can modify the cidr block use for pods. Pay attention to k8s version.

```
sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version 1.23.0
```
Use --apiserver-cert-extra-sans with your public ip to access cluster from outside AWS.
You also need to open port 6443 in you security group. Do open to everyone !


## Configure kubetcl

You can directly use the commands described in the output of previous step.
```
mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Configure kubectl networking with calico

```
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

# Set up the worker nodes

## Get join command on the worker

Print the join command
```
kubeadm token create --print-join-command
```

Now use the output on every worker to add them to the cluster
