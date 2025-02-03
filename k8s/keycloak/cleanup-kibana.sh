#!/bin/bash

# Установка пространства имен
NAMESPACE="logging"

# 1. Удаление подов, связанных с Kibana
echo "Удаляем поды, связанные с Kibana..."
kubectl delete pods -n $NAMESPACE -l app=kibana --ignore-not-found=true
kubectl delete pods -n $NAMESPACE -l job-name=pre-install-kibana-kibana --ignore-not-found=true

# 2. Удаление джобов, связанных с Kibana
echo "Удаляем джобы, связанные с Kibana..."
kubectl delete jobs -n $NAMESPACE -l app=kibana --ignore-not-found=true
kubectl delete job pre-install-kibana-kibana -n $NAMESPACE --ignore-not-found=true

# 3. Удаление конфигмэпов, связанных с Kibana
echo "Удаляем конфигмэпы, связанные с Kibana..."
kubectl delete configmaps -n $NAMESPACE -l app=kibana --ignore-not-found=true
kubectl delete configmap kibana-kibana-helm-scripts -n $NAMESPACE --ignore-not-found=true

# 4. Удаление PVC, связанных с Kibana
echo "Удаляем PVC, связанные с Kibana..."
kubectl delete pvc -n $NAMESPACE -l app=kibana --ignore-not-found=true

# 5. Удаление сервисных аккаунтов, связанных с Kibana
echo "Удаляем сервисные аккаунты, связанные с Kibana..."
kubectl delete serviceaccounts -n $NAMESPACE -l app=kibana --ignore-not-found=true
kubectl delete serviceaccount pre-install-kibana-kibana -n $NAMESPACE --ignore-not-found=true

# 6. Удаление ролей и rolebindings, связанных с Kibana
echo "Удаляем роли и rolebindings, связанные с Kibana..."
kubectl delete roles -n $NAMESPACE -l app=kibana --ignore-not-found=true
kubectl delete rolebindings -n $NAMESPACE -l app=kibana --ignore-not-found=true

# 7. Удаление секретов, связанных с Kibana
echo "Удаляем секреты, связанные с Kibana..."
kubectl delete secrets -n $NAMESPACE -l app=kibana --ignore-not-found=true
kubectl delete secret kibana-kibana-es-token -n $NAMESPACE --ignore-not-found=true

# 8. Удаление служебных компонентов Helm
echo "Удаляем служебные компоненты Helm, связанные с Kibana..."
kubectl delete all -n $NAMESPACE -l app.kubernetes.io/instance=kibana --ignore-not-found=true

# 9. Финальная проверка оставшихся ресурсов
echo "Проверяем оставшиеся ресурсы..."
kubectl get all -n $NAMESPACE | grep kibana

echo "Очистка завершена."

# chmod +x cleanup-kibana.sh
# ./cleanup-kibana.sh