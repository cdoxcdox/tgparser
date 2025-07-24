#!/bin/bash

# Скрипт для простой установки с минимальными зависимостями
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

# Полная очистка
full_cleanup() {
    log "Полная очистка npm и зависимостей..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    
    # Очистка npm кэша
    sudo -u telegram-parser npm cache clean --force 2>/dev/null || true
    npm cache clean --force 2>/dev/null || true
    
    # Удаление всех файлов npm
    sudo rm -rf "$PROJECT_DIR/node_modules" 2>/dev/null || true
    sudo rm -rf "$PROJECT_DIR/package-lock.json" 2>/dev/null || true
    sudo rm -rf "$PROJECT_DIR/.next" 2>/dev/null || true
    
    # Очистка глобального кэша
    sudo rm -rf /home/telegram-parser/.npm 2>/dev/null || true
    sudo rm -rf ~/.npm 2>/dev/null || true
    
    log "Очистка завершена ✓"
}

# Создание базового package.json
create_basic_package_json() {
    log "Создание базового package.json..."
    
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
    "next": "14.2.5",
    "react": "18.3.1",
    "react-dom": "18.3.1",
    "typescript": "5.5.4"
  },
  "devDependencies": {
    "@types/node": "20.14.11",
    "@types/react": "18.3.3",
    "@types/react-dom": "18.3.0",
    "eslint": "8.57.0",
    "eslint-config-next": "14.2.5"
  }
}
EOF
    
    log "Базовый package.json создан ✓"
}

# Установка базовых зависимостей
install_basic_dependencies() {
    log "Установка базовых зависимостей..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    cd "$PROJECT_DIR"
    
    # Установка с фиксированными версиями
    if sudo -u telegram-parser npm install --no-audit --no-fund --legacy-peer-deps; then
        log "Базовые зависимости установлены ✓"
        return 0
    else
        error "Не удалось установить базовые зависимости"
        return 1
    fi
}

# Добавление Tailwind CSS
add_tailwind() {
    log "Добавление Tailwind CSS..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    cd "$PROJECT_DIR"
    
    if sudo -u telegram-parser npm install tailwindcss@3.4.6 autoprefixer@10.4.19 postcss@8.4.39 --save --legacy-peer-deps; then
        log "Tailwind CSS установлен ✓"
        
        # Создание конфигурации Tailwind
        sudo -u telegram-parser tee "$PROJECT_DIR/tailwind.config.js" > /dev/null << 'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF
        
        # Создание postcss.config.js
        sudo -u telegram-parser tee "$PROJECT_DIR/postcss.config.js" > /dev/null << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF
        
        log "Конфигурация Tailwind создана ✓"
        return 0
    else
        warning "Не удалось установить Tailwind CSS"
        return 1
    fi
}

# Добавление иконок Lucide
add_lucide() {
    log "Добавление Lucide React..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    cd "$PROJECT_DIR"
    
    if sudo -u telegram-parser npm install lucide-react@0.400.0 --save --legacy-peer-deps; then
        log "Lucide React установлен ✓"
        return 0
    else
        warning "Не удалось установить Lucide React"
        return 1
    fi
}

# Создание базовых конфигурационных файлов
create_config_files() {
    log "Создание конфигурационных файлов..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    
    # next.config.js (простая версия)
    sudo -u telegram-parser tee "$PROJECT_DIR/next.config.js" > /dev/null << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    appDir: true,
  },
}

module.exports = nextConfig
EOF

    # tsconfig.json
    sudo -u telegram-parser tee "$PROJECT_DIR/tsconfig.json" > /dev/null << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
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

    # Создание app/globals.css
    sudo mkdir -p "$PROJECT_DIR/app"
    sudo -u telegram-parser tee "$PROJECT_DIR/app/globals.css" > /dev/null << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --foreground-rgb: 0, 0, 0;
  --background-start-rgb: 214, 219, 220;
  --background-end-rgb: 255, 255, 255;
}

@media (prefers-color-scheme: dark) {
  :root {
    --foreground-rgb: 255, 255, 255;
    --background-start-rgb: 0, 0, 0;
    --background-end-rgb: 0, 0, 0;
  }
}

body {
  color: rgb(var(--foreground-rgb));
  background: linear-gradient(
      to bottom,
      transparent,
      rgb(var(--background-end-rgb))
    )
    rgb(var(--background-start-rgb));
}
EOF

    log "Конфигурационные файлы созданы ✓"
}

# Создание простого layout.tsx
create_layout() {
    log "Создание layout.tsx..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    
    sudo -u telegram-parser tee "$PROJECT_DIR/app/layout.tsx" > /dev/null << 'EOF'
import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Telegram Channel Parser',
  description: 'Автоматический парсинг и фильтрация Telegram каналов',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ru">
      <body>{children}</body>
    </html>
  )
}
EOF

    log "Layout создан ✓"
}

# Создание простой страницы
create_simple_page() {
    log "Создание простой главной страницы..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    
    sudo -u telegram-parser tee "$PROJECT_DIR/app/page.tsx" > /dev/null << 'EOF'
'use client'

import { useState } from 'react'

export default function Home() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [loginForm, setLoginForm] = useState({ login: '', password: '' })

  const handleLogin = () => {
    if (loginForm.login === 'admin' && loginForm.password === 'admin') {
      setIsAuthenticated(true)
    } else {
      alert('Неверный логин или пароль')
    }
  }

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="bg-white p-8 rounded-lg shadow-md w-96">
          <h1 className="text-2xl font-bold mb-6 text-center">
            Telegram Channel Parser
          </h1>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Логин
              </label>
              <input
                type="text"
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md"
                value={loginForm.login}
                onChange={(e) => setLoginForm(prev => ({ ...prev, login: e.target.value }))}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Пароль
              </label>
              <input
                type="password"
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md"
                value={loginForm.password}
                onChange={(e) => setLoginForm(prev => ({ ...prev, password: e.target.value }))}
              />
            </div>
            <button
              onClick={handleLogin}
              className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700"
            >
              Войти
            </button>
          </div>
          <p className="text-sm text-gray-500 mt-4 text-center">
            Логин: admin, Пароль: admin
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <h1 className="text-xl font-semibold">Telegram Channel Parser</h1>
        </div>
      </div>
      
      <div className="max-w-7xl mx-auto px-4 py-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-lg font-semibold mb-4">Статистика</h2>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span>Обработано:</span>
                <span className="font-bold">0</span>
              </div>
              <div className="flex justify-between">
                <span>Переслано:</span>
                <span className="font-bold text-green-600">0</span>
              </div>
              <div className="flex justify-between">
                <span>Отфильтровано:</span>
                <span className="font-bold text-red-600">0</span>
              </div>
            </div>
          </div>
          
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-lg font-semibold mb-4">Подключение</h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Telegram API ID
                </label>
                <input
                  type="text"
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md"
                  placeholder="Введите API ID"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Telegram API Hash
                </label>
                <input
                  type="text"
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md"
                  placeholder="Введите API Hash"
                />
              </div>
              <button className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700">
                Подключиться
              </button>
            </div>
          </div>
          
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-lg font-semibold mb-4">Управление</h2>
            <div className="space-y-2">
              <button className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700">
                Запустить парсер
              </button>
              <button className="w-full bg-red-600 text-white py-2 px-4 rounded-md hover:bg-red-700">
                Остановить парсер
              </button>
              <button className="w-full bg-gray-600 text-white py-2 px-4 rounded-md hover:bg-gray-700">
                Просмотр логов
              </button>
            </div>
          </div>
        </div>
        
        <div className="mt-6 bg-white p-6 rounded-lg shadow">
          <h2 className="text-lg font-semibold mb-4">Информация</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div>
              <strong>Статус:</strong> Готов к настройке
            </div>
            <div>
              <strong>Версия:</strong> 1.0.0
            </div>
            <div>
              <strong>Node.js:</strong> {typeof window !== 'undefined' ? 'Загружено' : 'Сервер'}
            </div>
            <div>
              <strong>Последнее обновление:</strong> {new Date().toLocaleString()}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
EOF

    log "Простая страница создана ✓"
}

# Создание API маршрутов
create_api_routes() {
    log "Создание базовых API маршрутов..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    
    # Создание директорий API
    sudo mkdir -p "$PROJECT_DIR/app/api/parser/status"
    sudo mkdir -p "$PROJECT_DIR/app/api/telegram/connect"
    
    # API статуса парсера
    sudo -u telegram-parser tee "$PROJECT_DIR/app/api/parser/status/route.ts" > /dev/null << 'EOF'
import { NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json({
    success: true,
    statistics: {
      processed: 0,
      forwarded: 0,
      filtered: 0,
      uptime: 0,
      isRunning: false,
      lastProcessed: 'Никогда'
    }
  })
}
EOF

    # API подключения к Telegram
    sudo -u telegram-parser tee "$PROJECT_DIR/app/api/telegram/connect/route.ts" > /dev/null << 'EOF'
import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
  try {
    const { apiId, apiHash } = await request.json()
    
    if (!apiId || !apiHash) {
      return NextResponse.json(
        { success: false, error: 'API ID и Hash обязательны' },
        { status: 400 }
      )
    }
    
    // Симуляция подключения
    return NextResponse.json({
      success: true,
      message: 'Подключение к Telegram (демо режим)'
    })
  } catch (error) {
    return NextResponse.json(
      { success: false, error: 'Ошибка подключения' },
      { status: 500 }
    )
  }
}
EOF

    log "API маршруты созданы ✓"
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

# Тестирование приложения
test_application() {
    log "Тестирование приложения..."
    
    local PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"
    cd "$PROJECT_DIR"
    
    # Запуск в фоновом режиме для теста
    sudo -u telegram-parser timeout 10 npm start &
    local PID=$!
    
    sleep 5
    
    # Проверка доступности
    if curl -s http://localhost:3000 > /dev/null; then
        log "Приложение работает ✓"
        kill $PID 2>/dev/null || true
        return 0
    else
        warning "Приложение может не отвечать"
        kill $PID 2>/dev/null || true
        return 1
    fi
}

# Главная функция
main() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              Простая установка зависимостей                   ║"
    echo "║              Telegram Channel Parser                          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo
    
    check_root
    full_cleanup
    create_basic_package_json
    
    if install_basic_dependencies; then
        add_tailwind
        add_lucide
        create_config_files
        create_layout
        create_simple_page
        create_api_routes
        
        if build_application; then
            echo
            log "✅ Простая установка завершена успешно!"
            echo
            info "Что установлено:"
            info "  ✓ Next.js 14.2.5"
            info "  ✓ React 18.3.1"
            info "  ✓ TypeScript 5.5.4"
            info "  ✓ Tailwind CSS 3.4.6"
            info "  ✓ Lucide React (иконки)"
            info "  ✓ Базовый интерфейс"
            info "  ✓ API маршруты"
            echo
            info "Запуск приложения:"
            info "  telegram-parser start"
            echo
            info "Приложение будет доступно на: http://localhost:3000"
            info "Логин: admin, Пароль: admin"
            echo
            warning "Это базовая версия без сложных зависимостей."
            warning "Для полной функциональности потребуется дополнительная настройка."
        else
            error "Сборка не удалась"
            exit 1
        fi
    else
        error "Установка базовых зависимостей не удалась"
        exit 1
    fi
}

# Запуск
main "$@"
