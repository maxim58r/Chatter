#!/bin/bash

# Установка пространства имен
NAMESPACE="logging"

# 1. Удаление Helm релиза Elasticsearch
echo "Удаляем Helm релиз Elasticsearch..."
helm uninstall elasticsearch -n $NAMESPACE --no-hooks

# 2. Удаление StatefulSets Elasticsearch
echo "Удаляем StatefulSets Elasticsearch..."
kubectl delete statefulsets -l app=elasticsearch -n $NAMESPACE --ignore-not-found=true

# 3. Удаление подов Elasticsearch
echo "Удаляем поды Elasticsearch..."
kubectl delete pods -l app=elasticsearch -n $NAMESPACE --ignore-not-found=true --force --grace-period=0

# 4. Удаление PersistentVolumeClaims (PVC) Elasticsearch
echo "Удаляем PVC Elasticsearch..."
kubectl delete pvc -l app=elasticsearch -n $NAMESPACE --ignore-not-found=true

# 5. Удаление конфигмэпов Elasticsearch
echo "Удаляем конфигмэпы Elasticsearch..."
kubectl delete configmaps -l app=elasticsearch -n $NAMESPACE --ignore-not-found=true

# 6. Удаление секретов Elasticsearch
echo "Удаляем секреты Elasticsearch..."
kubectl delete secrets -l app=elasticsearch -n $NAMESPACE --ignore-not-found=true

# 7. Удаление служебных компонентов Elasticsearch
echo "Удаляем служебные компоненты Elasticsearch..."
kubectl delete serviceaccounts -l app=elasticsearch -n $NAMESPACE --ignore-not-found=true
kubectl delete roles -l app=elasticsearch -n $NAMESPACE --ignore-not-found=true
kubectl delete rolebindings -l app=elasticsearch -n $NAMESPACE --ignore-not-found=true

# 8. Удаление служебных джобов Elasticsearch
echo "Удаляем служебные джобы Elasticsearch..."
kubectl delete jobs -l app=elasticsearch -n $NAMESPACE --ignore-not-found=true

# 9. Финальная проверка оставшихся ресурсов
echo "Проверяем оставшиеся ресурсы Elasticsearch..."
kubectl get all -n $NAMESPACE | grep elasticsearch

echo "Очистка Elasticsearch завершена."

# chmod +x cleanup-elasticsearch.sh
# ./cleanup-elasticsearch.sh