#!/bin/bash

NAMESPACE=postgres
DB_NAME=postgres_shared
CLUSTER_NAME=postgres-shared
NODE_PORT=32172

echo "📦 Создание Postgres CRD..."
kubectl apply -f postgres-shared.yaml

echo "🌐 Создание NodePort сервиса..."
kubectl apply -f postgres-shared-nodeport.yaml

echo "⏳ Ожидание появления Pod..."
while [[ $(kubectl get pods -n $NAMESPACE -l cluster-name=$CLUSTER_NAME -o jsonpath='{.items[0].status.phase}') != "Running" ]]; do
  echo -n "."
  sleep 2
done

echo -e "\n🔐 Получение пароля из Secret..."
PASSWORD=$(kubectl get secret postgres.$CLUSTER_NAME.credentials.postgres -n $NAMESPACE -o jsonpath='{.data.password}' | base64 -d)

NODE_IP=$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo ""
echo "✅ Готово! Подключение к PostgreSQL:"
echo ""
echo "🔗 JDBC: jdbc:postgresql://$NODE_IP:$NODE_PORT/$DB_NAME"
echo "👤 Пользователь: postgres"
echo "🔑 Пароль: $PASSWORD"

# Сделай скрипт исполняемым:
# chmod +x deploy-postgres-shared.sh
# запуск
# ./deploy-postgres-shared.sh