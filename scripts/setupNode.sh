#!/bin/bash

set -e
set -u
set -o pipefail
IFS=$'\n\t'

message() {
  echo "######################################################################"
  echo "# $1"
  echo "######################################################################"
}

userCheck() {
  # Fail if running as root
  if [[ $(id -u) -eq 0 ]]; then
    message "ERROR: Can't run as root, exiting"
    exit 1
  else
    message "STATE: Running as $(id -u -n), continuing"
  fi
}

installPackages() {
  message "STATE: Updating system and installing packages"
  sudo apt-get update -q
  sudo apt-get upgrade -qy
  sudo apt-get autoremove -qy
}

installK3s() {
  message "STATE: Installing K3s"
  curl -sSL https://get.k3s.io | sh -s - server --cluster-init

  message "STATE: Sleeping for 15s"
  sleep 15

  message "STATE: Copying your kubeconfig file"
  mkdir -p "$HOME"/.kube
  sudo cp /etc/rancher/k3s/k3s.yaml "$HOME"/.kube/config
  sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config
  sed -i -e "s/127.0.0.1/$(hostname --fqdn)/g" "$HOME"/.kube/config
  export KUBECONFIG="$HOME"/.kube/config

  message "STATE: Getting cluster info"
  kubectl cluster-info

  message "STATE: Your kubeconfig is located at:   $HOME/.kube/config"
}

installApps() {
  message "STATE: Creating starter namespaces"
  kubectl apply -f ../cluster/namespaces/namespaces.yaml

  message "STATE: Creating traefik-dashboard"
  kubectl apply -f ../cluster/apps/dashboard/dashboard.yaml
}

userCheck
# installPackages
installK3s
installApps

message "STATE: Completed! Copy/paste this command into your terminal: export KUBECONFIG=\$HOME/.kube/config"