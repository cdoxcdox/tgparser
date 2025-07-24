#!/bin/bash

# Скрипт для исправления команд управления
# Версия: 1.0

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Проверка прав root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Не запускайте этот скрипт от имени root!"
        exit 1
    fi
}

# Создание скрипта управления
create_management_script() {
    log "Создание скрипта управления telegram-parser..."
    
    sudo tee /usr/local/bin/telegram-parser > /dev/null << 'EOF'
#!/bin/bash

PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
APP_USER="telegram-parser"

# Проверка существования пользователя
if ! id "$APP_USER" &>/dev/null; then
    echo "Ошибка: Пользователь $APP_USER не существует"
    exit 1
fi

# Проверка существования проекта
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "Ошибка: Директория проекта $PROJECT_DIR не существует"
    exit 1
fi

case "$1" in
    start)
        echo "Запуск Telegram Parser..."
        if sudo -u $APP_USER bash -c "cd $PROJECT_DIR && pm2 start ecosystem.config.js" 2>/dev/null; then
            echo "✓ Приложение запущено"
        else
            echo "✗ Ошибка запуска приложения"
            exit 1
        fi
        ;;
    stop)
        echo "Остановка Telegram Parser..."
        if sudo -u $APP_USER pm2 stop telegram-parser 2>/dev/null; then
            echo "✓ Приложение остановлено"
        else
            echo "✗ Ошибка остановки приложения"
        fi
        ;;
    restart)
        echo "Перезапуск Telegram Parser..."
        if sudo -u $APP_USER pm2 restart telegram-parser 2>/dev/null; then
            echo "✓ Приложение перезапущено"
        else
            echo "✗ Ошибка перезапуска приложения"
            exit 1
        fi
        ;;
    status)
        echo "Статус Telegram Parser:"
        sudo -u $APP_USER pm2 status telegram-parser 2>/dev/null || echo "Приложение не запущено"
        ;;
    logs)
        echo "Логи Telegram Parser:"
        sudo -u $APP_USER pm2 logs telegram-parser --lines 50
        ;;
    build)
        echo "Сборка приложения..."
        if sudo -u $APP_USER bash -c "cd $PROJECT_DIR && npm run build" 2>/dev/null; then
            echo "✓ Сборка завершена"
        else
            echo "✗ Ошибка сборки"
            exit 1
        fi
        ;;
    update)
        echo "Обновление зависимостей..."
        if sudo -u $APP_USER bash -c "cd $PROJECT_DIR && npm install && npm run build"; then
            echo "Перезапуск приложения..."
            sudo -u $APP_USER pm2 restart telegram-parser
            echo "✓ Обновление завершено"
        else
            echo "✗ Ошибка обновления"
            exit 1
        fi
        ;;
    install)
        echo "Установка приложения..."
        if sudo -u $APP_USER bash -c "cd $PROJECT_DIR && npm install"; then
            echo "✓ Зависимости установлены"
        else
            echo "✗ Ошибка установки зависимостей"
            exit 1
        fi
        ;;
    info)
        echo "=== Информация о системе ==="
        echo "Пользователь: $APP_USER"
        echo "Директория: $PROJECT_DIR"
        echo "Node.js: $(node --version 2>/dev/null || echo 'не установлен')"
        echo "npm: $(npm --version 2>/dev/null || echo 'не установлен')"
        echo "PM2: $(pm2 --version 2>/dev/null || echo 'не установлен')"
        echo ""
        echo "=== Статус сервисов ==="
        echo "Nginx: $(sudo systemctl is-active nginx 2>/dev/null || echo 'неактивен')"
        echo "Приложение: $(sudo -u $APP_USER pm2 list 2>/dev/null | grep telegram-parser | awk '{print $10}' || echo 'не запущено')"
        echo ""
        echo "=== Файлы проекта ==="
        if [[ -f "$PROJECT_DIR/package.json" ]]; then
            echo "✓ package.json существует"
        else
            echo "✗ package.json отсутствует"
        fi
        if [[ -d "$PROJECT_DIR/node_modules" ]]; then
            echo "✓ node_modules существует"
        else
            echo "✗ node_modules отсутствует"
        fi
        if [[ -d "$PROJECT_DIR/.next" ]]; then
            echo "✓ .next (сборка) существует"
        else
            echo "✗ .next (сборка) отсутствует"
        fi
        ;;
    *)
        echo "Telegram Channel Parser - Управление приложением"
        echo ""
        echo "Использование: $0 {команда}"
        echo ""
        echo "Команды:"
        echo "  start     - Запустить приложение"
        echo "  stop      - Остановить приложение"
        echo "  restart   - Перезапустить приложение"
        echo "  status    - Показать статус приложения"
        echo "  logs      - Показать логи приложения"
        echo "  build     - Собрать приложение"
        echo "  update    - Обновить зависимости и пересобрать"
        echo "  install   - Установить зависимости"
        echo "  info      - Показать информацию о системе"
        echo ""
        echo "Примеры:"
        echo "  $0 start"
        echo "  $0 logs"
        echo "  $0 info"
        exit 1
        ;;
esac
EOF
    
    sudo chmod +x /usr/local/bin/telegram-parser
    log "Скрипт управления создан ✓"
}

# Создание скрипта резервного копирования
create_backup_script() {
    log "Создание скрипта резервного копирования..."
    
    sudo tee /usr/local/bin/telegram-parser-backup > /dev/null << 'EOF'
#!/bin/bash

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/telegram-parser"
PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"

echo "Создание резервной копии..."

# Создание директории бэкапов
sudo mkdir -p $BACKUP_DIR

# Создание архива данных
if [[ -d "$PROJECT_DIR/data" ]] || [[ -d "$PROJECT_DIR/logs" ]]; then
    sudo tar -czf "$BACKUP_DIR/data_$DATE.tar.gz" -C "$PROJECT_DIR" data/ logs/ 2>/dev/null || true
    echo "✓ Данные и логи заархивированы"
else
    echo "⚠ Директории data/ и logs/ не найдены"
fi

# Копирование конфигурации
if [[ -f "$PROJECT_DIR/.env.local" ]]; then
    sudo cp "$PROJECT_DIR/.env.local" "$BACKUP_DIR/env_$DATE.backup" 2>/dev/null || true
    echo "✓ Конфигурация скопирована"
else
    echo "⚠ Файл .env.local не найден"
fi

# Удаление старых бэкапов (старше 30 дней)
sudo find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete 2>/dev/null || true
sudo find "$BACKUP_DIR" -name "*.backup" -mtime +30 -delete 2>/dev/null || true

echo "✓ Резервная копия создана: $DATE"
echo "Расположение: $BACKUP_DIR"
EOF
    
    sudo chmod +x /usr/local/bin/telegram-parser-backup
    log "Скрипт резервного копирования создан ✓"
}

# Проверка установки
check_installation() {
    log "Проверка установки..."
    
    # Проверка пользователя
    if ! id "telegram-parser" &>/dev/null; then
        error "Пользователь telegram-parser не существует"
        return 1
    fi
    
    # Проверка директории проекта
    if [[ ! -d "/home/telegram-parser/telegram-channel-parser" ]]; then
        error "Директория проекта не существует"
        return 1
    fi
    
    # Проверка основных файлов
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    local missing_files=()
    
    [[ ! -f "$PROJECT_DIR/package.json" ]] && missing_files+=("package.json")
    [[ ! -f "$PROJECT_DIR/.env.local" ]] && missing_files+=(".env.local")
    [[ ! -f "$PROJECT_DIR/ecosystem.config.js" ]] && missing_files+=("ecosystem.config.js")
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        warning "Отсутствуют файлы: ${missing_files[*]}"
        return 1
    fi
    
    log "Установка проверена ✓"
    return 0
}

# Установка недостающих компонентов
install_missing_components() {
    log "Установка недостающих компонентов..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    
    # Проверка и установка зависимостей
    if [[ ! -d "$PROJECT_DIR/node_modules" ]]; then
        warning "node_modules не найден, устанавливаем зависимости..."
        if sudo -u telegram-parser bash -c "cd $PROJECT_DIR && npm install"; then
            log "Зависимости установлены ✓"
        else
            error "Не удалось установить зависимости"
            return 1
        fi
    fi
    
    # Проверка и сборка приложения
    if [[ ! -d "$PROJECT_DIR/.next" ]]; then
        warning ".next не найден, собираем приложение..."
        if sudo -u telegram-parser bash -c "cd $PROJECT_DIR && npm run build"; then
            log "Приложение собрано ✓"
        else
            error "Не удалось собрать приложение"
            return 1
        fi
    fi
    
    return 0
}

# Настройка автозапуска PM2
setup_pm2_startup() {
    log "Настройка автозапуска PM2..."
    
    # Настройка startup для пользователя telegram-parser
    sudo -u telegram-parser pm2 startup systemd -u telegram-parser --hp /home/telegram-parser 2>/dev/null || true
    
    log "PM2 автозапуск настроен ✓"
}

# Проверка PATH
check_path() {
    log "Проверка PATH..."
    
    if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
        warning "Директория /usr/local/bin не в PATH"
        echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
        export PATH="/usr/local/bin:$PATH"
        log "PATH обновлен ✓"
    fi
}

# Тестирование команд
test_commands() {
    log "Тестирование команд..."
    
    # Тест команды telegram-parser
    if command -v telegram-parser &> /dev/null; then
        log "Команда telegram-parser доступна ✓"
        
        # Тест info команды
        if telegram-parser info &> /dev/null; then
            log "Команда telegram-parser info работает ✓"
        else
            warning "Команда telegram-parser info не работает"
        fi
    else
        error "Команда telegram-parser недоступна"
        return 1
    fi
    
    # Тест команды backup
    if command -v telegram-parser-backup &> /dev/null; then
        log "Команда telegram-parser-backup доступна ✓"
    else
        warning "Команда telegram-parser-backup недоступна"
    fi
    
    return 0
}

# Главная функция
main() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           Исправление команд управления                       ║"
    echo "║              Telegram Channel Parser                          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo
    
    check_root
    check_path
    create_management_script
    create_backup_script
    
    if check_installation; then
        install_missing_components
        setup_pm2_startup
        
        if test_commands; then
            echo
            log "✅ Все команды управления настроены успешно!"
            echo
            info "Доступные команды:"
            info "  telegram-parser start    - Запуск приложения"
            info "  telegram-parser stop     - Остановка приложения"
            info "  telegram-parser restart  - Перезапуск приложения"
            info "  telegram-parser status   - Статус приложения"
            info "  telegram-parser logs     - Логи приложения"
            info "  telegram-parser info     - Информация о системе"
            info "  telegram-parser-backup   - Резервная копия"
            echo
            info "Попробуйте: telegram-parser info"
        else
            error "Не все команды работают корректно"
            exit 1
        fi
    else
        error "Установка не завершена или повреждена"
        info "Запустите полную установку: ./quick-install.sh"
        exit 1
    fi
}

# Запуск
main "$@"
