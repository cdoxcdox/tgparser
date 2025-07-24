#!/bin/bash

# Скрипт для исправления зависимостей
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

# Очистка npm кэша
clean_npm_cache() {
    log "Очистка npm кэша..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    
    # Очистка от пользователя telegram-parser
    sudo -u telegram-parser npm cache clean --force 2>/dev/null || true
    
    # Удаление node_modules и package-lock.json
    if [[ -d "$PROJECT_DIR/node_modules" ]]; then
        sudo rm -rf "$PROJECT_DIR/node_modules"
        log "node_modules удален"
    fi
    
    if [[ -f "$PROJECT_DIR/package-lock.json" ]]; then
        sudo rm -f "$PROJECT_DIR/package-lock.json"
        log "package-lock.json удален"
    fi
    
    log "Кэш очищен ✓"
}

# Создание исправленного package.json
create_fixed_package_json() {
    log "Создание исправленного package.json..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    
    sudo -u telegram-parser tee "$PROJECT_DIR/package.json" > /dev/null << 'EOF'
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
    "next": "^14.2.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "typescript": "^5.0.0",
    "@types/node": "^20.0.0",
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "tailwindcss": "^3.4.0",
    "autoprefixer": "^10.4.14",
    "postcss": "^8.4.24",
    "@radix-ui/react-alert-dialog": "^1.0.4",
    "@radix-ui/react-button": "^1.0.3",
    "@radix-ui/react-card": "^1.0.4",
    "@radix-ui/react-dialog": "^1.0.4",
    "@radix-ui/react-input": "^1.0.3",
    "@radix-ui/react-label": "^2.0.2",
    "@radix-ui/react-progress": "^1.0.3",
    "@radix-ui/react-select": "^2.0.0",
    "@radix-ui/react-separator": "^1.0.3",
    "@radix-ui/react-slider": "^1.1.2",
    "@radix-ui/react-switch": "^1.0.3",
    "@radix-ui/react-tabs": "^1.0.4",
    "@radix-ui/react-textarea": "^1.0.3",
    "@radix-ui/react-toast": "^1.1.5",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.1.0",
    "lucide-react": "^0.400.0",
    "tailwind-merge": "^2.3.0",
    "tailwindcss-animate": "^1.0.7",
    "gram-js": "^2.15.7",
    "@ai-sdk/groq": "^0.0.52",
    "ai": "^3.3.0",
    "big-integer": "^1.6.52"
  },
  "devDependencies": {
    "eslint": "^8.57.0",
    "eslint-config-next": "^14.2.0"
  }
}
EOF
    
    log "package.json обновлен с правильными версиями ✓"
}

# Создание альтернативного package.json без AI SDK
create_minimal_package_json() {
    log "Создание минимального package.json без AI SDK..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    
    sudo -u telegram-parser tee "$PROJECT_DIR/package.json" > /dev/null << 'EOF'
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
    "next": "^14.2.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "typescript": "^5.0.0",
    "@types/node": "^20.0.0",
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "tailwindcss": "^3.4.0",
    "autoprefixer": "^10.4.14",
    "postcss": "^8.4.24",
    "@radix-ui/react-alert-dialog": "^1.0.4",
    "@radix-ui/react-button": "^1.0.3",
    "@radix-ui/react-card": "^1.0.4",
    "@radix-ui/react-dialog": "^1.0.4",
    "@radix-ui/react-input": "^1.0.3",
    "@radix-ui/react-label": "^2.0.2",
    "@radix-ui/react-progress": "^1.0.3",
    "@radix-ui/react-select": "^2.0.0",
    "@radix-ui/react-separator": "^1.0.3",
    "@radix-ui/react-slider": "^1.1.2",
    "@radix-ui/react-switch": "^1.0.3",
    "@radix-ui/react-tabs": "^1.0.4",
    "@radix-ui/react-textarea": "^1.0.3",
    "@radix-ui/react-toast": "^1.1.5",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.1.0",
    "lucide-react": "^0.400.0",
    "tailwind-merge": "^2.3.0",
    "tailwindcss-animate": "^1.0.7",
    "gram-js": "^2.15.7",
    "big-integer": "^1.6.52"
  },
  "devDependencies": {
    "eslint": "^8.57.0",
    "eslint-config-next": "^14.2.0"
  }
}
EOF
    
    log "Минимальный package.json создан ✓"
}

# Установка зависимостей
install_dependencies() {
    log "Установка зависимостей..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    
    cd "$PROJECT_DIR"
    
    # Попытка установки с исправленными версиями
    if sudo -u telegram-parser npm install --no-audit --no-fund; then
        log "Зависимости установлены успешно ✓"
        return 0
    else
        warning "Не удалось установить зависимости с AI SDK"
        
        # Попытка с минимальным набором
        create_minimal_package_json
        
        if sudo -u telegram-parser npm install --no-audit --no-fund; then
            log "Минимальные зависимости установлены ✓"
            return 0
        else
            error "Не удалось установить даже минимальные зависимости"
            return 1
        fi
    fi
}

# Добавление AI SDK отдельно
add_ai_sdk() {
    log "Попытка добавления AI SDK отдельно..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    cd "$PROJECT_DIR"
    
    # Попробуем установить AI SDK по отдельности
    if sudo -u telegram-parser npm install ai@latest; then
        log "AI SDK установлен ✓"
        
        # Попробуем установить Groq SDK
        if sudo -u telegram-parser npm install @ai-sdk/groq@latest; then
            log "Groq SDK установлен ✓"
        else
            warning "Groq SDK не установлен, но основная функциональность будет работать"
        fi
    else
        warning "AI SDK не установлен, AI фильтрация будет недоступна"
    fi
}

# Обновление API файла для работы без AI SDK
update_ai_api() {
    log "Обновление AI API для работы без SDK..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    local API_FILE="$PROJECT_DIR/app/api/ai/filter/route.ts"
    
    # Создаем директорию если не существует
    sudo mkdir -p "$(dirname "$API_FILE")"
    
    sudo -u telegram-parser tee "$API_FILE" > /dev/null << 'EOF'
import { type NextRequest, NextResponse } from "next/server"

export async function POST(request: NextRequest) {
  try {
    const { message, groqApiKey } = await request.json()

    if (!message) {
      return NextResponse.json(
        {
          success: false,
          error: "Сообщение не может быть пустым",
        },
        { status: 400 },
      )
    }

    if (!groqApiKey) {
      return NextResponse.json(
        {
          success: false,
          error: "Groq API ключ не указан",
        },
        { status: 400 },
      )
    }

    // Простая проверка на спам без AI SDK
    const spamKeywords = [
      'реклама', 'скидка', 'акция', 'купить', 'продать', 'заработок',
      'криптовалюта', 'инвестиции', 'прибыль', 'доход', 'млн', 'миллион'
    ]
    
    const messageText = message.toLowerCase()
    const isSpam = spamKeywords.some(keyword => messageText.includes(keyword))

    console.log("Простая проверка сообщения:", { message, isSpam })

    return NextResponse.json({
      success: true,
      isSpam,
      confidence: isSpam ? 0.7 : 0.3,
      analysis: isSpam ? "Обнаружены ключевые слова спама" : "Сообщение выглядит нормально",
    })
  } catch (error) {
    console.error("Ошибка фильтрации:", error)

    return NextResponse.json(
      {
        success: false,
        error: "Ошибка при анализе сообщения",
      },
      { status: 500 },
    )
  }
}
EOF
    
    log "AI API обновлен для работы без SDK ✓"
}

# Создание конфигурационных файлов
create_config_files() {
    log "Создание дополнительных конфигурационных файлов..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    
    # next.config.mjs
    sudo -u telegram-parser tee "$PROJECT_DIR/next.config.mjs" > /dev/null << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    serverComponentsExternalPackages: ['gram-js']
  },
  transpilePackages: ['lucide-react']
}

export default nextConfig
EOF

    # tailwind.config.ts
    sudo -u telegram-parser tee "$PROJECT_DIR/tailwind.config.ts" > /dev/null << 'EOF'
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
    sudo -u telegram-parser tee "$PROJECT_DIR/postcss.config.js" > /dev/null << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

    # tsconfig.json
    sudo -u telegram-parser tee "$PROJECT_DIR/tsconfig.json" > /dev/null << 'EOF'
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

    log "Конфигурационные файлы созданы ✓"
}

# Проверка установки
check_installation() {
    log "Проверка установки..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    
    # Проверка node_modules
    if [[ -d "$PROJECT_DIR/node_modules" ]]; then
        log "node_modules существует ✓"
        
        # Проверка основных пакетов
        local packages=("next" "react" "typescript" "tailwindcss")
        for package in "${packages[@]}"; do
            if [[ -d "$PROJECT_DIR/node_modules/$package" ]]; then
                log "$package установлен ✓"
            else
                warning "$package не найден"
            fi
        done
    else
        error "node_modules не найден"
        return 1
    fi
    
    return 0
}

# Сборка приложения
build_application() {
    log "Сборка приложения..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    cd "$PROJECT_DIR"
    
    if sudo -u telegram-parser npm run build; then
        log "Приложение собрано успешно ✓"
        return 0
    else
        error "Ошибка сборки приложения"
        return 1
    fi
}

# Главная функция
main() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              Исправление зависимостей                         ║"
    echo "║              Telegram Channel Parser                          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo
    
    check_root
    clean_npm_cache
    create_fixed_package_json
    
    if install_dependencies; then
        add_ai_sdk
        update_ai_api
        create_config_files
        
        if check_installation; then
            if build_application; then
                echo
                log "✅ Зависимости исправлены и приложение собрано!"
                echo
                info "Что было сделано:"
                info "  ✓ Очищен npm кэш"
                info "  ✓ Обновлен package.json с правильными версиями"
                info "  ✓ Установлены зависимости"
                info "  ✓ Добавлен AI SDK (если возможно)"
                info "  ✓ Обновлен AI API для работы без SDK"
                info "  ✓ Созданы конфигурационные файлы"
                info "  ✓ Приложение собрано"
                echo
                info "Теперь можно запустить: telegram-parser start"
            else
                warning "Зависимости установлены, но сборка не удалась"
                info "Попробуйте: telegram-parser build"
            fi
        else
            error "Проблемы с установкой зависимостей"
            exit 1
        fi
    else
        error "Не удалось установить зависимости"
        exit 1
    fi
}

# Запуск
main "$@"
