#!/bin/bash

# Установка пространства имен
NAMESPACE="keycloak"

# 1. Удаление Helm релиза keycloak
echo "Удаляем Helm релиз keycloak..."
helm uninstall keycloak -n $NAMESPACE --no-hooks

# 2. Удаление подов keycloak
echo "Удаляем поды keycloak..."
kubectl delete pods -l app=keycloak -n $NAMESPACE --ignore-not-found=true --force --grace-period=0

# 3. Удаление джобов keycloak
echo "Удаляем джобы keycloak..."
kubectl delete jobs -l app=keycloak -n $NAMESPACE --ignore-not-found=true --force --grace-period=0
kubectl delete job pre-install-keycloak-keycloak -n $NAMESPACE --ignore-not-found=true --force --grace-period=0

# 4. Удаление конфигмэпов keycloak
echo "Удаляем конфигмэпы keycloak..."
kubectl delete configmaps -l app=keycloak -n $NAMESPACE --ignore-not-found=true

# 5. Удаление PersistentVolumeClaims (PVC) keycloak
echo "Удаляем PVC keycloak..."
kubectl delete pvc -l app=keycloak -n $NAMESPACE --ignore-not-found=true

# 6. Удаление ролей и rolebindings keycloak
echo "Удаляем роли и rolebindings keycloak..."
kubectl delete roles -l app=keycloak -n $NAMESPACE --ignore-not-found=true
kubectl delete rolebindings -l app=keycloak -n $NAMESPACE --ignore-not-found=true
kubectl delete role pre-install-keycloak-keycloak -n $NAMESPACE --ignore-not-found=true
kubectl delete role post-delete-keycloak-keycloak -n $NAMESPACE --ignore-not-found=true
kubectl delete rolebinding pre-install-keycloak-keycloak -n $NAMESPACE --ignore-not-found=true
kubectl delete rolebinding post-delete-keycloak-keycloak -n $NAMESPACE --ignore-not-found=true

# 7. Удаление сервисных аккаунтов keycloak
echo "Удаляем сервисные аккаунты keycloak..."
kubectl delete serviceaccounts -l app=keycloak -n $NAMESPACE --ignore-not-found=true
kubectl delete serviceaccount pre-install-keycloak-keycloak -n $NAMESPACE --ignore-not-found=true
kubectl delete serviceaccount post-delete-keycloak-keycloak -n $NAMESPACE --ignore-not-found=true

# 8. Удаление секретов keycloak
#echo "Удаляем секреты keycloak..."
#kubectl delete secrets -l app=keycloak -n $NAMESPACE --ignore-not-found=true

# 9. Удаление служебных сервисов keycloak
echo "Удаляем службы keycloak..."
kubectl delete services -l app=keycloak -n $NAMESPACE --ignore-not-found=true

# 10. Финальная проверка оставшихся ресурсов
echo "Проверяем оставшиеся ресурсы keycloak..."
kubectl get all -n $NAMESPACE | grep keycloak

echo "Получение списка PVC в namespace $NAMESPACE..."
PVC_LIST=$(kubectl get pvc -n $NAMESPACE --no-headers -o custom-columns=":metadata.name")

if [ -z "$PVC_LIST" ]; then
  echo "Нет PVC для удаления в namespace $NAMESPACE."
  exit 0
fi

echo "Удаление PVC в namespace $NAMESPACE..."
for PVC in $PVC_LIST; do
  echo "Удаляем PVC: $PVC"
  kubectl delete pvc $PVC -n $NAMESPACE
done

echo "Все PVC удалены."

echo "Очистка keycloak завершена."
# chmod +x cleanup-keycloak.sh
# ./cleanup-keycloak.sh