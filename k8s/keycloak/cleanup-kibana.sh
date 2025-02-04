#!/bin/bash

# Установка пространства имен
NAMESPACE="logging"

# 1. Удаление Helm релиза Kibana
echo "Удаляем Helm релиз Kibana..."
helm uninstall kibana -n $NAMESPACE --no-hooks

# 2. Удаление подов Kibana
echo "Удаляем поды Kibana..."
kubectl delete pods -l app=kibana -n $NAMESPACE --ignore-not-found=true --force --grace-period=0

# 3. Удаление джобов Kibana
echo "Удаляем джобы Kibana..."
kubectl delete jobs -l app=kibana -n $NAMESPACE --ignore-not-found=true --force --grace-period=0
kubectl delete job pre-install-kibana-kibana -n $NAMESPACE --ignore-not-found=true --force --grace-period=0

# 4. Удаление конфигмэпов Kibana
echo "Удаляем конфигмэпы Kibana..."
kubectl delete configmaps -l app=kibana -n $NAMESPACE --ignore-not-found=true

# 5. Удаление PersistentVolumeClaims (PVC) Kibana
echo "Удаляем PVC Kibana..."
kubectl delete pvc -l app=kibana -n $NAMESPACE --ignore-not-found=true

# 6. Удаление ролей и rolebindings Kibana
echo "Удаляем роли и rolebindings Kibana..."
kubectl delete roles -l app=kibana -n $NAMESPACE --ignore-not-found=true
kubectl delete rolebindings -l app=kibana -n $NAMESPACE --ignore-not-found=true
kubectl delete role pre-install-kibana-kibana -n $NAMESPACE --ignore-not-found=true
kubectl delete role post-delete-kibana-kibana -n $NAMESPACE --ignore-not-found=true
kubectl delete rolebinding pre-install-kibana-kibana -n $NAMESPACE --ignore-not-found=true
kubectl delete rolebinding post-delete-kibana-kibana -n $NAMESPACE --ignore-not-found=true

# 7. Удаление сервисных аккаунтов Kibana
echo "Удаляем сервисные аккаунты Kibana..."
kubectl delete serviceaccounts -l app=kibana -n $NAMESPACE --ignore-not-found=true
kubectl delete serviceaccount pre-install-kibana-kibana -n $NAMESPACE --ignore-not-found=true
kubectl delete serviceaccount post-delete-kibana-kibana -n $NAMESPACE --ignore-not-found=true

# 8. Удаление секретов Kibana
echo "Удаляем секреты Kibana..."
kubectl delete secrets -l app=kibana -n $NAMESPACE --ignore-not-found=true

# 9. Финальная проверка оставшихся ресурсов
echo "Проверяем оставшиеся ресурсы Kibana..."
kubectl get all -n $NAMESPACE | grep kibana

echo "Очистка Kibana завершена."
# chmod +x cleanup-kibana.sh
# ./cleanup-kibana.sh