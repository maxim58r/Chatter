# Настройка Jenkins для CI/CD

## Установка
1. Установите Jenkins на сервере с Linux.
2. Установите плагины:
    - Docker Pipeline
    - Kubernetes CLI

## Настройка Docker
1. Добавьте Docker Host в Jenkins Credentials.
2. Убедитесь, что Jenkins имеет доступ к Docker:
   ```bash
   docker info
