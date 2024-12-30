# Документация по исправлениям и настройке Kubernetes и Jenkins Pipeline

## Цель
Обеспечить корректную работу сервисов через Kubernetes и их успешную проверку в Jenkins Pipeline.

## Исправления и действия

### 1. Настройка CoreDNS

#### Проблема:
CoreDNS не работал корректно, из-за чего доменные имена сервисов не резолвились.

#### Исправления:
- Проверили состояние Pod CoreDNS:
  ```bash
  kubectl -n kube-system get pods | grep coredns
  ```
- Перезапустили CoreDNS:
  ```bash
  kubectl -n kube-system rollout restart deployment/coredns
  ```
- Обновили ConfigMap для CoreDNS:
  ```yaml
  apiVersion: v1
  data:
    Corefile: |
      .:53 {
          errors
          health
          ready
          kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
          }
          prometheus :9153
          forward . /etc/resolv.conf
          cache 30
          loop
          reload
          loadbalance
      }
  kind: ConfigMap
  metadata:
    name: coredns
    namespace: kube-system
  ```
- Проверили, что CoreDNS перезагрузился без ошибок:
  ```bash
  kubectl -n kube-system logs -l k8s-app=kube-dns
  ```

### 2. Проверка и настройка Ingress Controller

#### Проблема:
Ingress Controller был настроен, но сервисы не отвечали по указанным хостам.

#### Исправления:
- Убедились, что Pod Ingress Controller работает:
  ```bash
  kubectl -n ingress-nginx get pods
  ```
- Проверили Service Ingress Controller:
  ```bash
  kubectl -n ingress-nginx get svc ingress-nginx-controller
  ```
- Проверили конфигурацию Ingress для authservice:
  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: authservice-ingress
    namespace: default
    annotations:
      kubernetes.io/ingress.class: "nginx"
  spec:
    rules:
      - host: authservice.local
        http:
          paths:
            - path: /
              pathType: Prefix
              backend:
                service:
                  name: authservice
                  port:
                    number: 8080
  ```
- Проверили доступность сервиса через NodePort:
  ```bash
  curl -v http://<NodeIP>:<NodePort>
  ```

### 3. Проверка и исправление Jenkins Pipeline

#### Проблема:
Health Check для сервисов не проходил из-за некорректной настройки хостов и портов.

#### Исправления:
- Обновили Health Check этап в `Jenkinsfile`:
  ```groovy
  stage('Health Check') {
      steps {
          script {
              def services = ['authservice', 'chatservice', 'messagingservice', 'notificationservice']
              services.each { service ->
                  sh """
                    echo "=== Performing Health Check for ${service} ==="
                    curl --fail http://${service}.local:<NodePort>/actuator/health || {
                        echo "Health check failed for ${service}"
                        exit 1
                    }
                  """
              }
          }
      }
  }
  ```
- Убедились, что в Jenkins настроены переменные окружения для Docker Hub и Kubernetes.
- Проверили успешное выполнение всех этапов Pipeline, включая деплой и Health Check.

### 4. Проверка доступности сервисов

#### Действия:
- Проверили резолвинг хостов:
  ```bash
  kubectl exec -it <pod-name> -- curl http://authservice.local:<NodePort>/actuator/health
  ```
- Убедились, что сервисы возвращают статус `UP` через Actuator.

## Результаты
Все сервисы успешно развернуты, доступны через Ingress Controller, и Health Check в Jenkins Pipeline прошёл без ошибок. Система работает стабильно.

## Рекомендации
1. Настроить мониторинг CoreDNS и Ingress Controller (например, через Prometheus).
2. Регулярно проверять доступность сервисов через Actuator.
3. Документировать изменения в конфигурации для упрощения поддержки.

## Ссылки на конфигурации
- `CoreDNS ConfigMap`: [см. выше]
- `Ingress для authservice`: [см. выше]
- `Jenkinsfile`: [см. выше]

