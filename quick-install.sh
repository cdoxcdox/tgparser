#!/bin/bash

# Telegram Channel Parser - Быстрая установка
# Версия: 1.1 - Исправлена обработка прав доступа
# Для Ubuntu 20.04+

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Функции логирования
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
        error "Используйте обычного пользователя с sudo правами"
        exit 1
    fi
}

# Проверка операционной системы
check_os() {
    if [[ ! -f /etc/os-release ]]; then
        error "Не удается определить операционную систему"
        exit 1
    fi
    
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        error "Этот скрипт предназначен только для Ubuntu"
        exit 1
    fi
    
    # Проверка версии Ubuntu
    VERSION_NUM=$(echo $VERSION_ID | cut -d. -f1)
    if [[ $VERSION_NUM -lt 20 ]]; then
        error "Требуется Ubuntu 20.04 или новее. Обнаружена версия: $VERSION_ID"
        exit 1
    fi
    
    log "Обнаружена Ubuntu $VERSION_ID ✓"
}

# Проверка системных требований
check_requirements() {
    log "Проверка системных требований..."
    
    # Проверка sudo прав
    if ! sudo -n true 2>/dev/null; then
        error "Пользователь не имеет sudo прав или требуется пароль"
        error "Убедитесь, что ваш пользователь в группе sudo"
        exit 1
    fi
    
    # Проверка RAM
    TOTAL_RAM=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    if [[ $TOTAL_RAM -lt 1 ]]; then
        warning "Обнаружено ${TOTAL_RAM}GB RAM. Рекомендуется минимум 1GB"
    else
        log "RAM: ${TOTAL_RAM}GB ✓"
    fi
    
    # Проверка свободного места
    FREE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $FREE_SPACE -lt 5 ]]; then
        error "Недостаточно свободного места. Требуется минимум 5GB, доступно: ${FREE_SPACE}GB"
        exit 1
    else
        log "Свободное место: ${FREE_SPACE}GB ✓"
    fi
    
    # Проверка интернет соединения
    if ! ping -c 1 google.com &> /dev/null; then
        error "Нет интернет соединения"
        exit 1
    else
        log "Интернет соединение ✓"
    fi
}

# Обновление системы
update_system() {
    log "Обновление системы..."
    sudo apt update -qq
    sudo apt upgrade -y -qq
    sudo apt install -y curl wget git unzip software-properties-common build-essential
    log "Система обновлена ✓"
}

# Установка Node.js
install_nodejs() {
    log "Установка Node.js 20..."
    
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ $NODE_VERSION -ge 18 ]]; then
            log "Node.js уже установлен: $(node --version) ✓"
            return 0
        fi
    fi
    
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - &>/dev/null
    sudo apt-get install -y nodejs &>/dev/null
    
    if ! command -v node &> /dev/null; then
        error "Не удалось установить Node.js"
        exit 1
    fi
    
    log "Node.js установлен: $(node --version) ✓"
    log "npm версия: $(npm --version) ✓"
}

# Установка PM2
install_pm2() {
    log "Установка PM2..."
    
    if command -v pm2 &> /dev/null; then
        log "PM2 уже установлен ✓"
        return 0
    fi
    
    sudo npm install -g pm2 &>/dev/null
    
    # Настройка автозапуска
    pm2 startup &>/dev/null || true
    
    log "PM2 установлен ✓"
}

# Установка Nginx
install_nginx() {
    log "Установка Nginx..."
    
    if command -v nginx &> /dev/null; then
        log "Nginx уже установлен ✓"
    else
        sudo apt install -y nginx &>/dev/null
    fi
    
    sudo systemctl enable nginx &>/dev/null
    sudo systemctl start nginx &>/dev/null
    
    log "Nginx установлен и запущен ✓"
}

# Создание пользователя
create_app_user() {
    local APP_USER="telegram-parser"
    
    if id "$APP_USER" &>/dev/null; then
        log "Пользователь $APP_USER уже существует ✓"
    else
        log "Создание пользователя $APP_USER..."
        sudo useradd -m -s /bin/bash $APP_USER
        sudo usermod -aG sudo $APP_USER
        log "Пользователь $APP_USER создан ✓"
    fi
    
    # Проверяем, что домашняя директория существует
    if [[ ! -d "/home/$APP_USER" ]]; then
        sudo mkdir -p "/home/$APP_USER"
        sudo chown $APP_USER:$APP_USER "/home/$APP_USER"
    fi
}

# Создание структуры проекта
setup_project() {
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    local APP_USER="telegram-parser"
    
    log "Настройка проекта..."
    
    # Удаляем существующую директорию если есть
    if [[ -d "$PROJECT_DIR" ]]; then
        sudo rm -rf "$PROJECT_DIR"
    fi
    
    # Создание директорий как root, затем смена владельца
    sudo mkdir -p "$PROJECT_DIR"/{data,logs,app/api/{parser/{control,status},telegram/{connect,channels},ai/filter,settings/save},components/ui,hooks,lib}
    
    # Создание дополнительных директорий
    sudo mkdir -p "$PROJECT_DIR"/{scripts,public}
    sudo mkdir -p "/backup/telegram-parser"
    
    # Установка правильных прав доступа
    sudo chown -R $APP_USER:$APP_USER "/home/telegram-parser"
    sudo chown -R $APP_USER:$APP_USER "/backup/telegram-parser"
    sudo chmod -R 755 "/home/telegram-parser"
    
    # Проверяем права доступа
    if [[ ! -w "$PROJECT_DIR" ]] && [[ $(stat -c %U "$PROJECT_DIR") != "$APP_USER" ]]; then
        error "Не удалось установить права доступа к $PROJECT_DIR"
        exit 1
    fi
    
    log "Структура проекта создана ✓"
}

# Создание файлов конфигурации
create_config_files() {
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    local APP_USER="telegram-parser"
    
    log "Создание файлов конфигурации..."
    
    # Переключаемся на пользователя telegram-parser для создания файлов
    sudo -u $APP_USER bash << 'USERSCRIPT'
PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"

# package.json
cat > "$PROJECT_DIR/package.json" << 'EOF'
{
  "name": "telegram-channel-parser",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "^15.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "typescript": "^5.0.0",
    "@types/node": "^20.0.0",
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "tailwindcss": "^3.3.0",
    "autoprefixer": "^10.4.14",
    "postcss": "^8.4.24",
    "@radix-ui/react-alert-dialog": "^1.0.4",
    "@radix-ui/react-button": "^1.0.3",
    "@radix-ui/react-card": "^1.0.4",
    "@radix-ui/react-dialog": "^1.0.4",
    "@radix-ui/react-input": "^1.0.3",
    "@radix-ui/react-label": "^1.0.3",
    "@radix-ui/react-progress": "^1.0.3",
    "@radix-ui/react-select": "^1.2.2",
    "@radix-ui/react-separator": "^1.0.3",
    "@radix-ui/react-slider": "^1.1.2",
    "@radix-ui/react-switch": "^1.0.3",
    "@radix-ui/react-tabs": "^1.0.4",
    "@radix-ui/react-textarea": "^1.0.3",
    "@radix-ui/react-toast": "^1.1.4",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.0.0",
    "lucide-react": "^0.263.1",
    "tailwind-merge": "^1.14.0",
    "tailwindcss-animate": "^1.0.6",
    "gram-js": "^2.15.7",
    "@ai-sdk/groq": "^0.0.15",
    "ai": "^3.0.0",
    "big-integer": "^1.6.51"
  },
  "devDependencies": {
    "eslint": "^8.45.0",
    "eslint-config-next": "^15.0.0"
  }
}
EOF

# next.config.mjs
cat > "$PROJECT_DIR/next.config.mjs" << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    serverComponentsExternalPackages: ['gram-js']
  }
}

export default nextConfig
EOF

# tailwind.config.ts
cat > "$PROJECT_DIR/tailwind.config.ts" << 'EOF'
import type { Config } from "tailwindcss"

const config: Config = {
  darkMode: ["class"],
  content: [
    './pages/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './app/**/*.{ts,tsx}',
    './src/**/*.{ts,tsx}',
  ],
  prefix: "",
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
} satisfies Config

export default config
EOF

# postcss.config.js
cat > "$PROJECT_DIR/postcss.config.js" << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# tsconfig.json
cat > "$PROJECT_DIR/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "lib": ["dom", "dom.iterable", "es6"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

# .env.local
cat > "$PROJECT_DIR/.env.local" << 'EOF'
# Telegram API (получите на https://my.telegram.org)
TELEGRAM_API_ID=your_api_id
TELEGRAM_API_HASH=your_api_hash

# Groq API (получите на https://console.groq.com)
GROQ_API_KEY=your_groq_key

# Администратор (установите свои данные)
ADMIN_LOGIN=admin
ADMIN_PASSWORD=change_me_please

# Настройки приложения
NODE_ENV=production
PORT=3000
EOF

# ecosystem.config.js
cat > "$PROJECT_DIR/ecosystem.config.js" << 'EOF'
module.exports = {
  apps: [{
    name: 'telegram-parser',
    script: 'npm',
    args: 'start',
    cwd: '/home/telegram-parser/telegram-channel-parser',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF

# .gitignore
cat > "$PROJECT_DIR/.gitignore" << 'EOF'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Next.js
.next/
out/

# Production
build/
dist/

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs
logs/
*.log

# Data
data/
*.session
*.session-journal

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
EOF

USERSCRIPT

    # Проверяем, что файлы созданы
    if [[ ! -f "$PROJECT_DIR/package.json" ]]; then
        error "Не удалось создать файлы конфигурации"
        exit 1
    fi
    
    log "Файлы конфигурации созданы ✓"
}

# Установка зависимостей
install_dependencies() {
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    local APP_USER="telegram-parser"
    
    log "Установка зависимостей npm (это может занять несколько минут)..."
    
    # Выполняем установку от имени пользователя telegram-parser
    sudo -u $APP_USER bash << USERSCRIPT
cd "$PROJECT_DIR"
export HOME="/home/telegram-parser"
npm install --silent --no-audit --no-fund
USERSCRIPT
    
    # Проверяем, что node_modules создан
    if [[ ! -d "$PROJECT_DIR/node_modules" ]]; then
        error "Не удалось установить зависимости npm"
        exit 1
    fi
    
    log "Зависимости установлены ✓"
}

# Сборка приложения
build_application() {
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    local APP_USER="telegram-parser"
    
    log "Сборка приложения..."
    
    # Выполняем сборку от имени пользователя telegram-parser
    sudo -u $APP_USER bash << USERSCRIPT
cd "$PROJECT_DIR"
export HOME="/home/telegram-parser"
npm run build
USERSCRIPT
    
    # Проверяем, что сборка прошла успешно
    if [[ ! -d "$PROJECT_DIR/.next" ]]; then
        error "Не удалось собрать приложение"
        exit 1
    fi
    
    log "Приложение собрано ✓"
}

# Настройка Nginx
configure_nginx() {
    local DOMAIN=${1:-$(curl -s ifconfig.me 2>/dev/null || echo "localhost")}
    
    log "Настройка Nginx для $DOMAIN..."
    
    sudo tee /etc/nginx/sites-available/telegram-parser > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    # Безопасность
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Логирование
    access_log /var/log/nginx/telegram-parser.access.log;
    error_log /var/log/nginx/telegram-parser.error.log;
    
    # Проксирование к Next.js
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Таймауты
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Статические файлы
    location /_next/static {
        proxy_pass http://127.0.0.1:3000;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }
    
    # Favicon
    location /favicon.ico {
        proxy_pass http://127.0.0.1:3000;
        add_header Cache-Control "public, max-age=86400";
    }
}
EOF
    
    # Активация конфигурации
    sudo ln -sf /etc/nginx/sites-available/telegram-parser /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Проверка и перезапуск
    if sudo nginx -t &>/dev/null; then
        sudo systemctl reload nginx
        log "Nginx настроен ✓"
    else
        error "Ошибка в конфигурации Nginx"
        sudo nginx -t
        exit 1
    fi
}

# Настройка файрвола
configure_firewall() {
    log "Настройка файрвола..."
    
    if ! command -v ufw &> /dev/null; then
        sudo apt install -y ufw &>/dev/null
    fi
    
    sudo ufw --force reset &>/dev/null
    sudo ufw default deny incoming &>/dev/null
    sudo ufw default allow outgoing &>/dev/null
    sudo ufw allow ssh &>/dev/null
    sudo ufw allow 80/tcp &>/dev/null
    sudo ufw allow 443/tcp &>/dev/null
    sudo ufw --force enable &>/dev/null
    
    log "Файрвол настроен ✓"
}

# Создание скриптов управления
create_management_scripts() {
    log "Создание скриптов управления..."
    
    # Основной скрипт управления
    sudo tee /usr/local/bin/telegram-parser > /dev/null << 'EOF'
#!/bin/bash

PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
APP_USER="telegram-parser"

case "$1" in
    start)
        echo "Запуск Telegram Parser..."
        sudo -u $APP_USER bash -c "cd $PROJECT_DIR && pm2 start ecosystem.config.js"
        ;;
    stop)
        echo "Остановка Telegram Parser..."
        sudo -u $APP_USER pm2 stop telegram-parser
        ;;
    restart)
        echo "Перезапуск Telegram Parser..."
        sudo -u $APP_USER pm2 restart telegram-parser
        ;;
    status)
        sudo -u $APP_USER pm2 status telegram-parser
        ;;
    logs)
        sudo -u $APP_USER pm2 logs telegram-parser
        ;;
    build)
        echo "Сборка приложения..."
        sudo -u $APP_USER bash -c "cd $PROJECT_DIR && npm run build"
        ;;
    update)
        echo "Обновление зависимостей..."
        sudo -u $APP_USER bash -c "cd $PROJECT_DIR && npm install && npm run build"
        sudo -u $APP_USER pm2 restart telegram-parser
        ;;
    *)
        echo "Использование: $0 {start|stop|restart|status|logs|build|update}"
        exit 1
        ;;
esac
EOF
    
    sudo chmod +x /usr/local/bin/telegram-parser
    
    # Скрипт резервного копирования
    sudo tee /usr/local/bin/telegram-parser-backup > /dev/null << 'EOF'
#!/bin/bash

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/telegram-parser"
PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"

sudo mkdir -p $BACKUP_DIR
sudo tar -czf "$BACKUP_DIR/data_$DATE.tar.gz" -C "$PROJECT_DIR" data/ logs/ 2>/dev/null || true
sudo cp "$PROJECT_DIR/.env.local" "$BACKUP_DIR/env_$DATE.backup" 2>/dev/null || true
sudo find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete 2>/dev/null || true
sudo find "$BACKUP_DIR" -name "*.backup" -mtime +30 -delete 2>/dev/null || true

echo "Backup completed: $DATE"
EOF
    
    sudo chmod +x /usr/local/bin/telegram-parser-backup
    
    # Настройка автоматического бэкапа
    (sudo crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/telegram-parser-backup") | sudo crontab -
    
    log "Скрипты управления созданы ✓"
}

# Запуск приложения
start_application() {
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    local APP_USER="telegram-parser"
    
    log "Запуск приложения..."
    
    # Запускаем приложение от имени пользователя telegram-parser
    sudo -u $APP_USER bash << USERSCRIPT
cd "$PROJECT_DIR"
export HOME="/home/telegram-parser"
pm2 start ecosystem.config.js
pm2 save
USERSCRIPT
    
    # Ожидание запуска
    sleep 10
    
    # Проверяем статус
    if sudo -u $APP_USER pm2 list | grep -q "telegram-parser.*online"; then
        log "Приложение запущено ✓"
    else
        warning "Приложение может не запуститься. Проверьте логи: telegram-parser logs"
    fi
}

# Финальная проверка
final_check() {
    log "Финальная проверка..."
    
    # Проверка Nginx
    if ! sudo systemctl is-active --quiet nginx; then
        warning "Nginx не запущен, пытаемся запустить..."
        sudo systemctl start nginx
    fi
    
    # Проверка приложения
    if ! sudo -u telegram-parser pm2 list | grep -q "telegram-parser.*online"; then
        warning "Приложение не запущено, проверьте логи"
    fi
    
    # Проверка доступности (с таймаутом)
    if timeout 10 curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000" | grep -q "200\|302"; then
        log "Приложение доступно ✓"
    else
        warning "Приложение может быть недоступно, но это нормально на первом запуске"
    fi
    
    log "Проверки завершены ✓"
}

# Вывод информации об установке
print_success_info() {
    local IP=$(curl -s ifconfig.me 2>/dev/null || echo "ваш_ip")
    
    echo
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    УСТАНОВКА ЗАВЕРШЕНА!                       ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo
    info "🌐 Приложение доступно по адресу: http://$IP"
    info "🔧 Порт: 3000"
    echo
    info "📋 Команды управления:"
    info "   telegram-parser start    - Запуск"
    info "   telegram-parser stop     - Остановка"
    info "   telegram-parser restart  - Перезапуск"
    info "   telegram-parser status   - Статус"
    info "   telegram-parser logs     - Логи"
    info "   telegram-parser-backup   - Резервная копия"
    echo
    warning "⚠️  ВАЖНО! Настройте API ключи в файле:"
    warning "   /home/telegram-parser/telegram-channel-parser/.env.local"
    echo
    info "📝 Для редактирования конфигурации:"
    info "   sudo nano /home/telegram-parser/telegram-channel-parser/.env.local"
    info "   telegram-parser restart"
    echo
    info "📚 Получите API ключи:"
    info "   • Telegram API: https://my.telegram.org"
    info "   • Groq AI: https://console.groq.com"
    echo
    info "🔒 Для настройки SSL сертификата:"
    info "   sudo apt install certbot python3-certbot-nginx"
    info "   sudo certbot --nginx -d ваш_домен.com"
    echo
    info "🔍 Если что-то не работает:"
    info "   telegram-parser logs     - Просмотр логов"
    info "   telegram-parser status   - Проверка статуса"
    info "   telegram-parser restart  - Перезапуск"
    echo
    log "🎉 Установка завершена успешно!"
    echo
}

# Обработка ошибок
handle_error() {
    local exit_code=$?
    local line_number=$1
    
    error "Ошибка на строке $line_number (код: $exit_code)"
    error "Установка прервана"
    
    # Попытка очистки
    if [[ -d "/home/telegram-parser/telegram-channel-parser" ]]; then
        warning "Удаление частично установленных файлов..."
        sudo rm -rf "/home/telegram-parser/telegram-channel-parser"
    fi
    
    exit $exit_code
}

# Основная функция
main() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              Telegram Channel Parser - Установка              ║"
    echo "║                        Версия 1.1                             ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo
    
    log "Начало установки..."
    
    check_root
    check_os
    check_requirements
    update_system
    install_nodejs
    install_pm2
    install_nginx
    create_app_user
    setup_project
    create_config_files
    install_dependencies
    build_application
    configure_nginx
    configure_firewall
    create_management_scripts
    start_application
    final_check
    print_success_info
}

# Обработка сигналов и ошибок
trap 'handle_error $LINENO' ERR
trap 'error "Установка прервана пользователем"; exit 1' INT TERM

# Запуск установки
main "$@"
