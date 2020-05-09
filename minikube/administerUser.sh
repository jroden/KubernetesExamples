#!/bin/bash

# Scenario: establish new user with X.509 cert auth strategy for k8s cluster
# 1) generate key for user
openssl genrsa -out test-user.key 2048

# 2) generate, submit, and approve certificate signed request for new user
openssl req -new -key test-user.key -out test-user.csr -subj "/CN=test-user/O=test-organization"
cat <<EOF | kubectl create -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: test-user-csr
spec:
  request: $(cat test-user.csr | base64 | tr -d '\n')
  username: test-user
  usages:
    - digital signature
    - key encipherment
    - server auth
    - client auth
EOF
kubectl certificate approve test-user-csr

# 3) set authorization role for new user
kubectl apply -f role.yml

# 4) set signed cert from k8s
kubectl get csr test-user-csr -o jsonpath='{.status.certificate}' | base64 --decode > test-user.crt
openssl x509 -in ./test-user.crt -noout -text # verify the signed cert has expected name and organization

# 5) set user credentials using signed cert & key
kubectl config set-credentials test-user --client-certificate=./test-user.crt --client-key=./test-user.key
kubectl config set-context test-context --cluster=minikube --user=test-user

# 6) test access
kubectl config use-context test-context
kubectl get pods -n development
