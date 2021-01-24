# Docker

apt-get remove docker docker-engine docker.io containerd runc

apt-get update

apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -

apt-key fingerprint 0EBFCD88

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

apt-get update

# apt-get install docker-ce docker-ce-cli containerd.io

apt-cache madison docker-ce

apt-get install docker-ce=5:19.03.14~3-0~debian-buster docker-ce-cli=5:19.03.14~3-0~debian-buster containerd.io

cat <<EOF | tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

systemctl daemon-reload
systemctl restart docker

systemctl enable docker.service
systemctl enable containerd.service

docker run --rm hello-world



# Kubernetes

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

apt-get update && apt-get install -y apt-transport-https curl

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

kubeadm init --dry-run

# kubeadm init
# kubeadm init --pod-network-cidr=172.16.0.0/12 -> pour calico
# kubeadm init --apiserver-cert-extra-sans home.dietz.dev -> pour avoir un DNS perso
# kubeadm init --pod-network-cidr=172.16.0.0/12 --apiserver-cert-extra-sans home.dietz.dev

# curl https://docs.projectcalico.org/manifests/calico.yaml -O
# kubectl apply -f calico.yaml

# kubectl taint nodes --all node-role.kubernetes.io/master-

# join



# curl https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended.yaml -O
# mv recommended.yaml dashboard.yaml
# kubectl apply -f dashboard.yaml
# kubectl proxy

# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Create token to add in configuration
TOKEN=$(kubectl -n kube-system describe secret default| awk '$1=="token:"{print $2}')
kubectl config set-credentials kubernetes-admin --token="${TOKEN}" -> replace kubernetes-admin with name in config
