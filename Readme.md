# mTLS-playground

The goal of this repo is to deploy an app secured with mTLS on k3d.

# Requirements

- k3d v5.6.3
- helm v3.13.1
- kubectl v1.28.10
- terraform v1.8.4

# Steps

```bash
sudo bash -c "cat >>/etc/hosts <<EOF
127.0.0.1 vault.local
127.0.0.1 app.local
EOF"

k3d cluster create -p "80:80@loadbalancer"  -p "443:443@loadbalancer"
helm repo add hashicorp https://helm.releases.hashicorp.com
helm upgrade -n vault --install --create-namespace vault hashicorp/vault --values vault.yml

# Wait a bit for the vault (in dev mode) to start and its root token to be created
sleep 60
export VAULT_ADDR="http://vault.local"
export VAULT_TOKEN="root"

terraform init
terraform apply -auto-approve

# Fetch root CA and trust it
sudo bash -c "terraform output -raw root_ca  > /usr/local/share/ca-certificates/custom_ca.crt"
sudo update-ca-certificates

# Create backend TLS secret
terraform output -raw backend_cert  > backend.pem
terraform output -raw backend_key  > backend.key
kubectl create ns app
kubectl create secret tls -n app backend-tls --cert=backend.pem --key=backend.key

# Create backend secret
terraform output -raw root_ca  > root_ca.pem
kubectl create secret generic root-ca -n app --from-file ca.crt=root_ca.pem

# Apply app manifests
kubectl apply -f app.yaml

# Get client certs and curl the app
terraform output -raw client_cert > client.pem
terraform output -raw client_key > client.key

# Test with or without client cert + fake_client
curl https://app.local
curl --cert fake_client.pem --key fake_client.key https://app.local
curl --cert client.pem --key client.key https://app.local

# Util allowing to generate the p12 for chrome
openssl pkcs12 -export -out jlebloas.p12 -inkey client.key -in client.pem
```

Note that fake_client.key are pushed there on purpose allowing simple quick tests with a client cert not signed by the trusted root CA.

# Tear-down

```bash
sudo rm /usr/local/share/ca-certificates/custom_ca.crt
sudo update-ca-certificates
terraform apply -auto-approve --destroy
helm uninstall -n vault vault
k3d cluster delete k3s-default
```

Plus remove the /etc/hosts entries
