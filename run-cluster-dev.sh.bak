#!/bin/sh

# https://github.com/nuclio/nuclio/blob/master/docs/setup/minikube/getting-started-minikube.md
# cf. NOTES for installation details

# Prepare Minikube
# ----------------
# Start Minikube
minikube start --vm-driver=virtualbox --extra-config=apiserver.authorization-mode=RBAC
# Set admin permissions (RBAC)
kubectl apply -f https://raw.githubusercontent.com/nuclio/nuclio/master/hack/minikube/resources/kubedns-rbac.yaml
# Bring up a Docker registry inside Minikube
minikube ssh -- docker run -d -p 5000:5000 registry:2

# Install Nuclio
# --------------
# Create a Nuclio namespace
kubectl create namespace nuclio
# Create the RABC roles
kubectl apply -f https://raw.githubusercontent.com/nuclio/nuclio/master/hack/k8s/resources/nuclio-rbac.yaml
# Deploy Nuclio to the cluster
kubectl apply -f https://raw.githubusercontent.com/nuclio/nuclio/master/hack/k8s/resources/nuclio.yaml
# Forward the Nuclio dashboard port
# Must wait for Nuclio to be deployed, that takes about 1mn to complete
# Check with: kubectl get pods --namespace nuclio
# kubectl port-forward -n nuclio $(kubectl get pods -n nuclio -l nuclio.io/app=dashboard -o jsonpath='{.items[0].metadata.name}') 8070:8070