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

  message "STATE: Creating kubeconfig file"
  export KUBECONFIG=~/.kube/config
  mkdir ~/.kube 2> /dev/null
  sudo k3s kubectl config view --raw > "$KUBECONFIG"
  chmod 600 "$KUBECONFIG"

  message "STATE: Getting cluster info"
  kubectl cluster-info

  message "STATE: Your kubeconfig is located at:   $HOME/.kube/config"
}

installApps() {
  message "STATE: Creating starter namespaces"
  kubectl apply -f ../cluster/namespaces/namespaces.yaml

  message "STATE: Registering traefik dashboard"
  kubectl apply -f ../cluster/dashboard/dashboard.yaml
}

userCheck
# installPackages
installK3s
installApps

message "STATE: Completed! Copy/paste this command into your terminal: export KUBECONFIG=\$HOME/.kube/config"