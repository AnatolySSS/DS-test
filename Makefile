# Загрузка переменных из .env
include .env.dev
export

# Переменные
DOCKER_COMPOSE=docker-compose
DEV_COMPOSE_FILE=docker-compose.dev.yaml
ENV_DEV_FILE=.env.dev

# Среда разработки
DB_DEV_CONTAINER_NAME = invent-db-dev
DB_DEV_NAME = dev_db
BACKUP_DEV_FILE = latest.dev_db.sql.gz

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
	@echo ""
	@echo "  $(GREEN)РАБОТА С БАЗОЙ ДАННЫХ"
	@echo "  $(YELLOW)list-backups$(NC)         - Список доступных бэкапов"
	@echo "  $(GREEN)Среда разработки:"
	@echo "  $(YELLOW)restore-db-dev$(NC)       - Восстановление базы данных из backup...(опционально: BACKUP_DEV_FILE=backup_dev_file.sql.gz)"
	@echo "  $(YELLOW)restore-db-dev-int$(NC)   - Альтернативный вариант восстановления базы данных с явным указанием пароля"
	@echo "  $(YELLOW)backup-db-dev$(NC)        - Полное резервное копирование базы данных (ручное)"




# Проверка наличия docker-compose
check-docker-compose:
	@which docker-compose > /dev/null 2>&1 || (echo "$(RED)docker-compose не установлен$(NC)" && exit 1)


# КОНТЕЙНЕРЫ
## ОБЩИЕ НАСТРОЙКИ
### Остановка контейнеров
.PHONY: down
down: check-docker-compose
	@echo "$(YELLOW)Остановка контейнеров...$(NC)"
	$(DOCKER_COMPOSE) -f $(DEV_COMPOSE_FILE) down --volumes --remove-orphans

### Очистка Docker-ресурсов
.PHONY: clean
clean: check-docker-compose
	@echo "$(YELLOW)Полная очистка Docker-ресурсов...$(NC)"
	@echo "Остановка и удаление всех контейнеров..."
	$(DOCKER_COMPOSE) -f $(DEV_COMPOSE_FILE) down --volumes --remove-orphans
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