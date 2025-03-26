#!/bin/bash

set -euo pipefail

NAMESPACE="redis"
CLUSTER_NAME="redis-shared"
NODE_PORT="32179"
PORT="6379"

echo "📦 Применяем Redis CRD..."
kubectl apply -f redis-shared-crd.yaml

echo "🌐 Применяем NodePort сервис..."
kubectl apply -f redis-shared-nodeport.yaml

echo "⏳ Ожидаем, пока Redis Pod будет готов..."
while true; do
  READY=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance="$CLUSTER_NAME" \
    -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || echo "")
  if [[ "$READY" == "true" ]]; then
    echo -e "\n✅ Redis Pod готов!"
    break
  fi
  echo -n "."
  sleep 2
done

echo "🔐 Ищем Secret с автосгенерированным паролем..."
SECRET_NAME=$(kubectl get secrets -n "$NAMESPACE" -o name | grep "$CLUSTER_NAME" | grep -E 'auth|secret' | head -n1 || true)

if [[ -z "$SECRET_NAME" ]]; then
  echo "❌ Не найден Secret с паролем."
  exit 1
fi

PASSWORD=$(kubectl get "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath="{.data.password}" | base64 -d)

NODE_IP=$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo ""
echo "✅ Redis готов к подключению:"
echo ""
echo "🔗 redis://:$PASSWORD@$NODE_IP:$NODE_PORT"
echo "📦 Host: $NODE_IP"
echo "🔑 Пароль: $PASSWORD"


# Сделай скрипт исполняемым:
# chmod +x deploy-redis-shared.sh
# Запусти:
# ./deploy-redis-shared.sh