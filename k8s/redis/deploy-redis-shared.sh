#!/bin/bash

set -euo pipefail

NAMESPACE="redis"
CLUSTER_NAME="redis-shared"
PORT="6379"
NODE_PORT="32179"
PASSWORD="CfAb11y5gLQ3quvc" # такой же, как в YAML

echo "📦 Применяем CRD для Redis..."
kubectl apply -f redis-shared-crd.yaml

echo "🌐 Применяем NodePort сервис..."
kubectl apply -f redis-shared-nodeport.yaml

echo -n "⏳ Ожидаем, пока Redis Pod запустится..."
while true; do
  POD_READY=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance="$CLUSTER_NAME" -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || echo "")
  if [[ "$POD_READY" == "true" ]]; then
    echo -e "\n✅ Redis $CLUSTER_NAME готов!"
    break
  fi
  echo -n "."
  sleep 3
done

NODE_IP=$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo ""
echo "✅ Всё готово! Подключение к Redis:"
echo ""
echo "🔗 redis://:$PASSWORD@$NODE_IP:$NODE_PORT"
echo "📦 Host: $NODE_IP"
echo "🔑 Пароль: $PASSWORD"

# Сделай скрипт исполняемым:
# chmod +x deploy-redis-shared.sh
# Запусти:
# ./deploy-redis-shared.sh