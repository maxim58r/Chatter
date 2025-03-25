#!/bin/bash

set -euo pipefail

NAMESPACE="postgres"
CLUSTER_NAME="postgres-shared"
DB_NAME="postgres_shared"
NODE_PORT="32172"
USERNAME="postgres"

echo "📦 Применяем CRD для PostgreSQL кластера..."
kubectl apply -f postgres-shared-crd.yaml

echo "🌐 Применяем NodePort сервис..."
kubectl apply -f postgres-shared-nodeport.yaml

echo -n "⏳ Ожидаем, пока кластер появится и будет готов..."
while true; do
  STATUS=$(kubectl get postgresql "$CLUSTER_NAME" -n "$NAMESPACE" -o jsonpath='{.status.PostgresClusterStatus}' 2>/dev/null || echo "")
  if [[ "$STATUS" == "Running" ]]; then
    echo -e "\n✅ Кластер $CLUSTER_NAME готов!"
    break
  fi
  echo -n "."
  sleep 3
done

echo -n "🔐 Ожидаем появления Secret с паролем пользователя $USERNAME..."
while true; do
  SECRET_NAME=$(kubectl get secret -n "$NAMESPACE" -o name | grep "^secret/${USERNAME}\.${CLUSTER_NAME}\.credentials\.postgresql\.acid\.zalan\.do" || true)
  if [[ -n "$SECRET_NAME" ]]; then
    echo -e "\n✅ Secret найден: $SECRET_NAME"
    break
  fi
  echo -n "."
  sleep 2
done

echo ""
echo "🔑 Извлекаем пароль пользователя $USERNAME..."
PASSWORD=$(kubectl get "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.password}' | base64 -d)

NODE_IP=$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo ""
echo "✅ Всё готово! Детали подключения к PostgreSQL:"
echo ""
echo "🔗 JDBC: jdbc:postgresql://${NODE_IP}:${NODE_PORT}/${DB_NAME}"
echo "👤 Пользователь: $USERNAME"
echo "🔑 Пароль: $PASSWORD"



# Сделай скрипт исполняемым:
# chmod +x deploy-postgres-shared.sh
# запуск
# ./deploy-postgres-shared.sh