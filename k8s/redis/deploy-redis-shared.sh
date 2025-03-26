#!/bin/bash
NAMESPACE=redis
RELEASE=redis-shared
PASSWORD="CfAb11y5gLQ3quvc"

echo "🔐 Создаём namespace и секрет с паролем..."
kubectl create ns $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic redis-password --from-literal=redis-password=$PASSWORD -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "📦 Установка Redis через Helm с NodePort..."
helm repo add bitnami https://charts.bitnami.com/bitnami || true
helm repo update

helm upgrade --install $RELEASE bitnami/redis \
  --namespace $NAMESPACE \
  --set auth.enabled=true \
  --set auth.existingSecret=redis-password \
  --set auth.existingSecretPasswordKey=redis-password \
  --set replica.replicaCount=0 \
  --set persistence.enabled=true \
  --set persistence.storageClass=local-path \
  --set master.service.type=NodePort \
  --set master.service.nodePort=32179

echo -e "\\n✅ Redis установлен c NodePort = 32179."
echo "Проверь IP командой:"
echo "kubectl get svc -n $NAMESPACE"
echo "redis-cli -h <NODE_IP> -p 32179 -a $PASSWORD ping"

