#!/bin/sh

echo "arch:        $ARCH"
echo "runc:        $RUNC_VERSION"
echo "containerd:  $CONTAINERD_VERSION"
echo "crictl:      $CRICTL_VERSION"
echo "kubernetes:  $K8S_VERSION"

# Configure containerd
echo "Installing containerd"
curl -sSLO https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz
tar Cxzf /usr/local containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz
rm -f containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz
mkdir -p /usr/local/lib/systemd/system
curl -sL https://raw.githubusercontent.com/containerd/containerd/main/containerd.service | tee /usr/local/lib/systemd/system/containerd.service > /dev/null

if [ ! -d /etc/containerd ]; then mkdir /etc/containerd; fi
# Set REGISTRY env variable
curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/lab/containerd/config.toml | envsubst | tee /etc/containerd/config.toml > /dev/null

systemctl daemon-reload
systemctl enable --now containerd

# Install runc
echo "Installing runc"
curl -sLO https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.${ARCH}
install -m 755 runc.${ARCH} /usr/local/bin/runc
rm -f runc.${ARCH}

# Install and configure crictl
echo "Installing crictl"
curl -sLO https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRICTL_VERSION}/crictl-v${CRICTL_VERSION}-linux-${ARCH}.tar.gz
tar zxf crictl-v${CRICTL_VERSION}-linux-${ARCH}.tar.gz -C /usr/local/bin
rm -f crictl-v${CRICTL_VERSION}-linux-${ARCH}.tar.gz
cat <<EOF | tee /etc/crictl.yaml > /dev/null
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
EOF

# Installing kubeadm
echo "Installing kubeadm"
curl -sLO https://dl.k8s.io/release/v${K8S_VERSION}/bin/linux/${ARCH}/kubeadm
install kubeadm /usr/local/bin/kubeadm
rm -f kubeadm

# Installing kubelet
# NOTE: kubeadm does not create /etc/kubernetes/manifests directory. Make dir by hand
echo "Installing kubelet"
curl -sLO https://dl.k8s.io/release/v${K8S_VERSION}/bin/linux/${ARCH}/kubelet
install kubelet /usr/local/bin/kubelet
rm -f kubelet
RELEASE_VERSION="v0.16.2"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubelet/kubelet.service" | sed "s:/usr/bin:/usr/local/bin:g" | tee /usr/local/lib/systemd/system/kubelet.service > /dev/null
mkdir -p /usr/local/lib/systemd/system/kubelet.service.d
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:/usr/local/bin:g" | tee /usr/local/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl enable --now kubelet