#!/bin/bash

# Установка пространства имен
NAMESPACE="elastic-system"
KIBANA_NAME="kibana-kb"
ELASTICSEARCH_NAME="elastic-cluster-es-default"

# 1. Удаление ресурса Kibana через деплоймент
echo "Удаляем деплоймент Kibana..."
kubectl delete deployment $KIBANA_NAME -n $NAMESPACE --ignore-not-found=true

# 2. Удаление сервисов Kibana
echo "Удаляем сервисы Kibana..."
kubectl delete service $KIBANA_NAME-http -n $NAMESPACE --ignore-not-found=true
kubectl delete service elastic-operator-webhook -n $NAMESPACE --ignore-not-found=true

# 3. Удаление StatefulSets Elasticsearch и Elastic-Operator
echo "Удаляем StatefulSet Elasticsearch..."
kubectl delete statefulset $ELASTICSEARCH_NAME -n $NAMESPACE --ignore-not-found=true
kubectl delete statefulset elastic-operator -n $NAMESPACE --ignore-not-found=true

# 4. Удаление подов Kibana и Elasticsearch
echo "Удаляем поды Kibana и Elasticsearch..."
kubectl delete pod -l app=$KIBANA_NAME -n $NAMESPACE --ignore-not-found=true --force --grace-period=0
kubectl delete pod -l app=elasticsearch -n $NAMESPACE --ignore-not-found=true --force --grace-period=0
kubectl delete pod elastic-operator-0 -n $NAMESPACE --ignore-not-found=true --force --grace-period=0

# 5. Удаление PersistentVolumeClaims (PVC) Elasticsearch
echo "Удаляем PVC Elasticsearch..."
kubectl delete pvc -l app=elasticsearch -n $NAMESPACE --ignore-not-found=true

# 6. Удаление конфигмэпов и секретов Kibana и Elasticsearch
echo "Удаляем конфигмэпы и секреты Kibana и Elasticsearch..."

# Удаление конфигмэпов
kubectl delete configmaps -l app=$KIBANA_NAME -n $NAMESPACE --ignore-not-found=true
kubectl delete configmaps -l app=elasticsearch -n $NAMESPACE --ignore-not-found=true

# Удаление секретов
kubectl delete secrets \
  elastic-cluster-es-default-es-config \
  elastic-cluster-es-default-es-transport-certs \
  elastic-cluster-es-elastic-user \
  elastic-cluster-es-http-ca-internal \
  elastic-cluster-es-http-certs-internal \
  elastic-cluster-es-http-certs-public \
  elastic-cluster-es-internal-users \
  elastic-cluster-es-remote-ca \
  elastic-cluster-es-transport-ca-internal \
  elastic-cluster-es-transport-certs-public \
  elastic-cluster-es-xpack-file-realm \
  elastic-operator-webhook-cert \
  elastic-system-kibana-kibana-user \
  kibana-kb-config \
  kibana-kb-es-ca \
  kibana-kb-http-ca-internal \
  kibana-kb-http-certs-internal \
  kibana-kb-http-certs-public \
  kibana-kibana-user \
  oidc-client-secret \
  sh.helm.release.v1.elastic-operator.v1 \
  -n $NAMESPACE --ignore-not-found=true

# 7. Удаление служебных компонентов Elasticsearch и Kibana
echo "Удаляем служебные компоненты Elasticsearch и Kibana..."
kubectl delete serviceaccounts -l app=$KIBANA_NAME -n $NAMESPACE --ignore-not-found=true
kubectl delete serviceaccounts -l app=elasticsearch -n $NAMESPACE --ignore-not-found=true
kubectl delete roles -l app=$KIBANA_NAME -n $NAMESPACE --ignore-not-found=true
kubectl delete roles -l app=elasticsearch -n $NAMESPACE --ignore-not-found=true
kubectl delete rolebindings -l app=$KIBANA_NAME -n $NAMESPACE --ignore-not-found=true
kubectl delete rolebindings -l app=elasticsearch -n $NAMESPACE --ignore-not-found=true

# 8. Удаление служебных джобов Elasticsearch и Kibana
echo "Удаляем служебные джобы Elasticsearch и Kibana..."
kubectl delete jobs -l app=$KIBANA_NAME -n $NAMESPACE --ignore-not-found=true
kubectl delete jobs -l app=elasticsearch -n $NAMESPACE --ignore-not-found=true

# 9. Финальная проверка оставшихся ресурсов
echo "Проверяем оставшиеся ресурсы Elasticsearch и Kibana..."
kubectl get all -n $NAMESPACE | grep -e elasticsearch -e kibana

echo "Очистка Kibana и Elasticsearch завершена."

# chmod +x cleanup-kibana-elasticsearch.sh
# ./cleanup-kibana-elasticsearch.sh
