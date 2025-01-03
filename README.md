# 🛠️ **ChatterProject**

**ChatterProject** — мультимодульный микросервисный мессенджер с асинхронной архитектурой для обработки высокой нагрузки. Проект предназначен для обмена сообщениями между пользователями с поддержкой масштабируемости, отказоустойчивости и мониторинга.

---

## ⚖️ **Основные возможности**
- **➡️ Высокая производительность**: поддержка более **12 млн QPS** с горизонтальным масштабированием.
- **⏳ Асинхронная архитектура**: обмен сообщениями через **Kafka**.
- **⚖️ Отказоустойчивость**: резервное копирование и репликация данных.
- **🔒 Безопасность**: аутентификация на основе **JWT** и хранение секретов в **Vault**.
- **🔄 Масштабируемость**: поддержка Kubernetes и микросервисной архитектуры.
- **📊 Мониторинг**: интеграция с **Prometheus**, **Grafana**, **Jaeger** и **Zipkin**.

---

## 📏 **Архитектура проекта**

### **1. Общая структура**
```
ChatterProject/
|│-- api-gateway/          # API Gateway для маршрутизации и rate limiting
|│-- auth-service/        # Сервис аутентификации (JWT + Vault)
|│-- messaging-service/   # Сервис для отправки и хранения сообщений (Kafka + Cassandra)
|│-- chat-service/        # Сервис управления чатами (PostgreSQL)
|│-- notification-service/ # Сервис уведомлений
|│-- disaster-recovery/   # Сервис резервного копирования
|│-- monitoring/          # Метрики и трассировка
|│-- kubernetes/          # Манифесты для развертывания
|│-- docs/                # Документация и схемы
|│-- scripts/             # Скрипты для автоматизации
|│-- README.md            # Описание проекта
```

---

## ⚙️ **Технологический стек**

| Компонент                  | Технология               |
|----------------------------|--------------------------|
| **API Gateway**            | NGINX Ingress Controller |
| **Аутентификация**         | Spring Security + JWT, Vault |
| **Сообщения**              | Kafka + Cassandra        |
| **Управление чатами**      | PostgreSQL + Spring Data |
| **Уведомления**            | Kafka Consumer           |
| **Мониторинг и Трассировка** | Prometheus, Grafana, Jaeger, Zipkin |
| **Оркестрация**            | Kubernetes               |
| **Отказоустойчивость**     | DR для Cassandra, PostgreSQL, Redis |
| **CI/CD**                  | GitHub Actions           |

---

## 🔢 **Сервисы**

### **1. API Gateway**
- Проверка аутентификации JWT.
- Rate Limiting.
- Маршрутизация запросов к микросервисам.

### **2. Authentication Service**
- Аутентификация пользователей с использованием **JWT**.
- Хранение секретов в **Vault**.
- Кэширование токенов в **Redis**.

### **3. Messaging Service**
- Асинхронная отправка сообщений через **Kafka**.
- Хранение сообщений в **Cassandra**.

### **4. Chat Service**
- Управление чатами (создание чатов, добавление участников).
- Хранение данных в **PostgreSQL**.

### **5. Notification Service**
- Подписка на события Kafka и отправка уведомлений пользователям.

### **6. Disaster Recovery Service**
- Резервное копирование и репликация данных из **Cassandra**, **Redis** и **PostgreSQL**.
- Репликация Kafka топиков.

### **7. Monitoring**
- Сбор и отображение метрик через **Prometheus** и **Grafana**.
- Трассировка запросов с помощью **Jaeger** и **Zipkin**.

---

## 💡 **Запуск проекта**

### **1. Локальный запуск**

#### 🔗 **Предварительные требования**
- **Docker** и **Docker Compose**.
- **Java 21+**.
- **Kubernetes** (для тестирования масштабирования).
- **Helm** (для развертывания в Kubernetes).

#### 🔄 **Шаги**
1. Клонируйте репозиторий:
   ```bash
   git clone https://github.com/maxim58r/Chatter
   cd Chatter
   ```

2. Запустите инфраструктуру через Docker Compose:
   ```bash
   docker-compose up -d
   ```

3. Запустите микросервисы локально через Maven:
   ```bash
   cd auth-service && mvn spring-boot:run
   cd messaging-service && mvn spring-boot:run
   cd chat-service && mvn spring-boot:run
   ```

4. Для Kubernetes развертывания используйте Helm:
   ```bash
   helm install chatter ./kubernetes/chatter-chart
   ```

### **2. Мониторинг**
- **Prometheus**: `http://localhost:9090`
- **Grafana**: `http://localhost:3000`
- **Jaeger**: `http://localhost:16686`

---

## ⚛️ **CI/CD**
- Пайплайны CI/CD реализованы с использованием **GitHub Actions**.
- Автоматическое тестирование и деплой на Kubernetes-кластер.

---

## 📊 **Мониторинг и логирование**
- **Prometheus**: сбор метрик.
- **Grafana**: визуализация данных и дашборды.
- **Jaeger/Zipkin**: распределенная трассировка.
- **ELK Stack**: сбор и анализ логов.

---

## 🛡️ **Безопасность**
- Использование **Vault** для управления секретами.
- Аутентификация через **JWT**.
- Шифрование данных в Cassandra и PostgreSQL.

---

## 🔍 **Дальнейшие улучшения**
1. Реализация **Rate Limiting** с динамическими правилами.
2. Добавление поддержи **WebSockets** для реального времени.
3. Оптимизация Kafka для более высокой производительности.
4. Расширенные сценарии Disaster Recovery.

---

## 🛠 **Авторы**
- **Максим Серов** – *Архитектор и разработчик.*

---

## ✉️ **Контакты**
- Email: maxim558r@gmail.com
- LinkedIn: [Maxim Serov](https://www.linkedin.com/in/maxim-serov-45aa33100/)

---

## 📅 **Лицензия**
Этот проект распространяется под лицензией **MIT**. Подробнее смотрите в файле [LICENSE](LICENSE).
