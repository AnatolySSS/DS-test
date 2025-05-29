# Загрузка переменных из .env
include .env.prod
include .env.dev
export

# Переменные
DOCKER_COMPOSE=docker-compose
DEV_COMPOSE_FILE=docker-compose.dev.yaml
PROD_COMPOSE_FILE=docker-compose.prod.yaml
ENV_PROD_FILE=.env.prod
ENV_DEV_FILE=.env.dev

# Среда разработки
DB_DEV_CONTAINER_NAME = invent-db-dev
DB_DEV_NAME = dev_db
BACKUP_DEV_FILE = latest.dev_db.sql.gz

# Продакшен среда
DB_PROD_CONTAINER_NAME = invent-db-prod
DB_PROD_NAME = prod_db
BACKUP_PROD_FILE = latest.prod_db.sql.gz

# Цвета для вывода
GREEN = \033[0;32m
YELLOW = \033[0;33m
NC = \033[0m




# Цель по умолчанию
.PHONY: help
help:
	@echo "$(GREEN)Доступные команды:$(NC)"
	@echo ""
	@echo "  $(GREEN)РАБОТА С ДОКЕР КОНТЕЙНЕРОМ"
	@echo "  $(YELLOW)make down$(NC)            - Остановка и удаление контейнеров, сетей и т.д."
	@echo "  $(YELLOW)make clean$(NC)           - Удаление всех Docker-ресурсов"
	@echo "  $(GREEN)Среда разработки:"
	@echo "  $(YELLOW)make build-dev$(NC)       - Сборка Docker-образа среды разработки"
	@echo "  $(YELLOW)make dev$(NC)             - Запуск Docker-контейнеров с пробросом портов"
	@echo "  $(YELLOW)make logs-dev$(NC)        - Просмотр логов среды разработки"
	@echo "  $(GREEN)Продакшен среда:"
	@echo "  $(YELLOW)make build-prod$(NC)      - Сборка Docker-образа продакшен-среды"
	@echo "  $(YELLOW)make prod$(NC)            - Запуск Docker-контейнеров с пробросом портов"
	@echo "  $(YELLOW)make logs-prod$(NC)       - Просмотр логов продакшен-среды"
	@echo ""
	@echo "  $(GREEN)РАБОТА С БАЗОЙ ДАННЫХ"
	@echo "  $(YELLOW)list-backups$(NC)         - Список доступных бэкапов"
	@echo "  $(GREEN)Среда разработки:"
	@echo "  $(YELLOW)restore-db-dev$(NC)       - Восстановление базы данных из backup...(опционально: BACKUP_DEV_FILE=backup_dev_file.sql.gz)"
	@echo "  $(YELLOW)restore-db-dev-int$(NC)   - Альтернативный вариант восстановления базы данных с явным указанием пароля"
	@echo "  $(YELLOW)backup-db-dev$(NC)        - Полное резервное копирование базы данных (ручное)"
	@echo "  $(GREEN)Продакшен среда:"
	@echo "  $(YELLOW)restore-db-prod$(NC)      - Восстановление базы данных из backup...(опционально: BACKUP_DEV_FILE=backup_dev_file.sql.gz)"
	@echo "  $(YELLOW)restore-db-prod-int$(NC)  - Альтернативный вариант восстановления базы данных с явным указанием пароля"
	@echo "  $(YELLOW)backup-db-prod$(NC)       - Полное резервное копирование базы данных (ручное)"




# Проверка наличия docker-compose
check-docker-compose:
	@which docker-compose > /dev/null 2>&1 || (echo "$(RED)docker-compose не установлен$(NC)" && exit 1)


# КОНТЕЙНЕРЫ
## ОБЩИЕ НАСТРОЙКИ
### Остановка контейнеров
.PHONY: down
down: check-docker-compose
	@echo "$(YELLOW)Остановка контейнеров...$(NC)"
	$(DOCKER_COMPOSE) -f $(PROD_COMPOSE_FILE) down --volumes --remove-orphans

### Очистка Docker-ресурсов
.PHONY: clean
clean: check-docker-compose
	@echo "$(YELLOW)Полная очистка Docker-ресурсов...$(NC)"
	@echo "Остановка и удаление всех контейнеров..."
	$(DOCKER_COMPOSE) -f $(PROD_COMPOSE_FILE) down --volumes --remove-orphans
	@echo "Удаление всех Docker-образов..."
	docker rmi -f $(shell docker images -aq) || true
	@echo "Удаление всех Docker-томов..."
	docker volume prune -f
	@echo "Очистка неиспользуемых Docker-сетей..."
	docker network prune -f
	@echo "$(GREEN)Очистка завершена$(NC)"




## НАСТРОЙКИ ДЛЯ СРЕДЫ РАЗРАБОТКИ
### Сборка Docker-образа среды разработки
.PHONY: build-dev
build-dev: check-docker-compose
	@echo "$(GREEN)Сборка Docker-образа среды разработки...$(NC)"
	$(DOCKER_COMPOSE) --env-file ${ENV_DEV_FILE} -f $(DEV_COMPOSE_FILE) build --no-cache

### Запуск среды разработки
.PHONY: dev
dev: check-docker-compose
	@echo "$(GREEN)Запуск среды разработки...$(NC)"
	$(DOCKER_COMPOSE) --env-file ${ENV_DEV_FILE} -f $(DEV_COMPOSE_FILE) up -d

### Просмотр логов среды разработки
.PHONY: logs-dev
logs-dev: check-docker-compose
	@echo "$(GREEN)Просмотр логов среды разработки...$(NC)"
	$(DOCKER_COMPOSE) --env-file ${ENV_DEV_FILE} -f $(DEV_COMPOSE_FILE) logs -f




## НАСТРОЙКИ ДЛЯ ПРОДАКШЕН СРЕДЫ
### Сборка Docker-образа продакшен-среды
.PHONY: build-prod
build-prod: check-docker-compose
	@echo "$(GREEN)Сборка Docker-образа продакшен-среды...$(NC)"
	$(DOCKER_COMPOSE) --env-file ${ENV_PROD_FILE} -f $(PROD_COMPOSE_FILE) build --no-cache

### Запуск продакшен-среды
.PHONY: prod
prod: check-docker-compose
	@echo "$(GREEN)Запуск продакшен-среды...$(NC)"
	$(DOCKER_COMPOSE) --env-file ${ENV_PROD_FILE} -f $(PROD_COMPOSE_FILE) up -d

### Просмотр логов продакшен-среды
.PHONY: logs-prod
logs-prod: check-docker-compose
	@echo "$(GREEN)Просмотр логов продакшен-среды....$(NC)"
	$(DOCKER_COMPOSE) --env-file ${ENV_PROD_FILE} -f $(PROD_COMPOSE_FILE) logs -f



# БАЗЫ ДАННЫХ
## ОБЩИЕ НАСТРОЙКИ
### Список доступных бэкапов
.PHONY: list-backups
list-backups:
	@echo "$(GREEN)Доступные бэкапы:$(NC)"
	@ls -l ./backups/*.sql.gz




## НАСТРОЙКИ ДЛЯ СРЕДЫ РАЗРАБОТКИ
### Восстановление базы данных из backup
.PHONY: restore-db-dev
restore-db-dev:
	@echo "$(GREEN)Восстановление базы данных из backup...$(NC)"
	@if [ -z "$(BACKUP_DEV_FILE)" ]; then \
			echo "$(YELLOW)Укажите файл бэкапа: make restore-db BACKUP_DEV_FILE=backup_dev_file.sql.gz$(NC)"; \
			exit 1; \
	fi
	@if [ ! -f "./backups/$(BACKUP_DEV_FILE)" ]; then \
			echo "$(RED)Файл бэкапа не найден: ./backups/$(BACKUP_DEV_FILE)$(NC)"; \
			exit 1; \
	fi
	@docker cp ./backups/$(BACKUP_DEV_FILE) $(DB_DEV_CONTAINER_NAME):/backups/
	@docker exec -i $(DB_DEV_CONTAINER_NAME) sh -c 'zcat /backups/$(BACKUP_DEV_FILE) | mysql -u root -p$(MYSQL_ROOT_PASSWORD) $(DB_DEV_NAME)'
	@echo "$(GREEN)Восстановление базы данных завершено$(NC)"

### Альтернативный вариант с явным указанием пароля
.PHONY: restore-db-dev-int
restore-db-dev-int:
	@echo "$(GREEN)Интерактивное восстановление базы данных...$(NC)"
	@read -p "Введите имя файла бэкапа (например, latest.dev_db.sql.gz): " backup_file; \
	read -sp "Введите пароль root для MySQL: " db_password; \
	docker cp ./backups/$$backup_file $(DB_DEV_CONTAINER_NAME):/backups/; \
	docker exec -i $(DB_DEV_CONTAINER_NAME) sh -c "zcat /backups/$$backup_file | mysql -u root -p$$db_password $(DB_DEV_NAME)"

### Полное резервное копирование базы данных
.PHONY: backup-db-dev
backup-db-dev:
	@echo "$(GREEN)Создание резервной копии базы данных...$(NC)"
	@docker exec $(DB_DEV_CONTAINER_NAME) mysqldump -u root -p$(MYSQL_ROOT_PASSWORD) $(DB_DEV_NAME) | gzip > ./backups/manual_backup_dev_$$(date +"%d.%m.%Y_%H.%M.%S").sql.gz
	@echo "$(GREEN)Резервная копия создана$(NC)"




## НАСТРОЙКИ ДЛЯ ПРОДАКШЕН СРЕДЫ
### Восстановление базы данных из backup
.PHONY: restore-db-prod
restore-db-prod:
	@echo "$(GREEN)Восстановление базы данных из backup...$(NC)"
	@if [ -z "$(BACKUP_PROD_FILE)" ]; then \
			echo "$(YELLOW)Укажите файл бэкапа: make restore-db BACKUP_PROD_FILE=backup_prod_file.sql.gz$(NC)"; \
			exit 1; \
	fi
	@if [ ! -f "./backups/$(BACKUP_PROD_FILE)" ]; then \
			echo "$(RED)Файл бэкапа не найден: ./backups/$(BACKUP_PROD_FILE)$(NC)"; \
			exit 1; \
	fi
	@docker cp ./backups/$(BACKUP_PROD_FILE) $(DB_PROD_CONTAINER_NAME):/backups/
	@docker exec -i $(DB_PROD_CONTAINER_NAME) sh -c 'zcat /backups/$(BACKUP_PROD_FILE) | mysql -u root -p$(MYSQL_ROOT_PASSWORD) $(DB_PROD_NAME)'
	@echo "$(GREEN)Восстановление базы данных завершено$(NC)"

### Альтернативный вариант с явным указанием пароля
.PHONY: restore-db-prod-int
restore-db-prod-int:
	@echo "$(GREEN)Интерактивное восстановление базы данных...$(NC)"
	@read -p "Введите имя файла бэкапа (например, latest.prod_db.sql.gz): " backup_file; \
	read -sp "Введите пароль root для MySQL: " db_password; \
	docker cp ./backups/$$backup_file $(DB_PROD_CONTAINER_NAME):/backups/; \
	docker exec -i $(DB_PROD_CONTAINER_NAME) sh -c "zcat /backups/$$backup_file | mysql -u root -p$$db_password $(DB_PROD_NAME)"

### Полное резервное копирование базы данных
.PHONY: backup-db-prod
backup-db-prod:
	@echo "$(GREEN)Создание резервной копии базы данных...$(NC)"
	@docker exec $(DB_PROD_CONTAINER_NAME) mysqldump -u root -p$(MYSQL_ROOT_PASSWORD) $(DB_PROD_NAME) | gzip > ./backups/manual_backup_prod_$$(date +"%d.%m.%Y_%H.%M.%S").sql.gz
	@echo "$(GREEN)Резервная копия создана$(NC)"