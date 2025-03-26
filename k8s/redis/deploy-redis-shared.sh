#!/bin/bash
NAMESPACE=redis
RELEASE=redis-shared
PASSWORD="MySecurePassword"

echo "🔐 Создаём namespace и секрет с паролем..."
kubectl create ns $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic redis-password --from-literal=redis-password=$PASSWORD -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "📦 Установка Redis через Helm..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm upgrade --install $RELEASE bitnami/redis \
  --namespace $NAMESPACE \
  --set auth.enabled=true \
  --set auth.existingSecret=redis-password \
  --set auth.existingSecretPasswordKey=redis-password \
  --set replica.replicaCount=0 \
  --set persistence.enabled=true \
  --set persistence.storageClass=local-path \
  --set service.type=LoadBalancer

echo -e "\n✅ Готово! Проверь командой:"
echo "kubectl get svc -n $NAMESPACE"
echo "redis-cli -h <EXTERNAL-IP> -a $PASSWORD ping"
