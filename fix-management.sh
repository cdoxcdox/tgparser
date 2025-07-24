#!/bin/bash

# Скрипт для исправления стилей и переменных окружения
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

PROJECT_DIR="/home/telegram-parser/telegram-channel-parser"

# Исправление стилей
fix_styles() {
    log "Исправление стилей..."
    
    # Обновляем globals.css с правильными стилями
    sudo -u telegram-parser tee "$PROJECT_DIR/app/globals.css" > /dev/null << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Базовые стили */
* {
  box-sizing: border-box;
  padding: 0;
  margin: 0;
}

html,
body {
  max-width: 100vw;
  overflow-x: hidden;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

body {
  color: #000000;
  background: #ffffff;
}

/* Убираем проблемные градиенты */
@layer base {
  html {
    @apply text-gray-900 bg-white;
  }
  
  body {
    @apply text-gray-900 bg-white;
  }
}

/* Кастомные стили для форм */
.form-input {
  @apply block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm 
         focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500
         text-gray-900 bg-white;
}

.btn {
  @apply px-4 py-2 rounded-md font-medium transition-colors duration-200
         focus:outline-none focus:ring-2 focus:ring-offset-2;
}

.btn-primary {
  @apply bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500;
}

.btn-success {
  @apply bg-green-600 text-white hover:bg-green-700 focus:ring-green-500;
}

.btn-danger {
  @apply bg-red-600 text-white hover:bg-red-700 focus:ring-red-500;
}

.btn-secondary {
  @apply bg-gray-600 text-white hover:bg-gray-700 focus:ring-gray-500;
}

/* Карточки */
.card {
  @apply bg-white rounded-lg shadow-md border border-gray-200;
}

.card-header {
  @apply px-6 py-4 border-b border-gray-200;
}

.card-body {
  @apply px-6 py-4;
}

/* Статистика */
.stat-card {
  @apply bg-white p-6 rounded-lg shadow-md border border-gray-200;
}

.stat-number {
  @apply text-2xl font-bold text-gray-900;
}

.stat-label {
  @apply text-sm font-medium text-gray-600;
}

/* Статусы */
.status-online {
  @apply inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
         bg-green-100 text-green-800;
}

.status-offline {
  @apply inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
         bg-red-100 text-red-800;
}

.status-warning {
  @apply inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
         bg-yellow-100 text-yellow-800;
}

/* Индикаторы */
.indicator-green {
  @apply w-3 h-3 bg-green-500 rounded-full;
}

.indicator-red {
  @apply w-3 h-3 bg-red-500 rounded-full;
}

.indicator-yellow {
  @apply w-3 h-3 bg-yellow-500 rounded-full;
}

/* Анимации */
.pulse-slow {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Темная тема (опционально) */
@media (prefers-color-scheme: dark) {
  html {
    @apply text-gray-100 bg-gray-900;
  }
  
  body {
    @apply text-gray-100 bg-gray-900;
  }
  
  .card {
    @apply bg-gray-800 border-gray-700;
  }
  
  .form-input {
    @apply bg-gray-800 border-gray-600 text-gray-100;
  }
}
EOF

    log "Стили исправлены ✓"
}

# Создание правильного .env.local
create_env_file() {
    log "Создание файла переменных окружения..."
    
    # Создаем .env.local с правильными переменными
    sudo -u telegram-parser tee "$PROJECT_DIR/.env.local" > /dev/null << 'EOF'
# Telegram API (получите на https://my.telegram.org)
TELEGRAM_API_ID=your_api_id
TELEGRAM_API_HASH=your_api_hash

# Groq API (получите на https://console.groq.com)
GROQ_API_KEY=your_groq_key

# Администратор (установите свои данные)
ADMIN_LOGIN=admin
ADMIN_PASSWORD=admin

# Настройки приложения
NODE_ENV=production
PORT=3000
NEXT_PUBLIC_APP_NAME=Telegram Channel Parser
NEXT_PUBLIC_APP_VERSION=1.0.0

# Настройки парсера
PARSER_DELAY_MIN=15
PARSER_DELAY_MAX=30
PARSER_MAX_MESSAGES=100

# Безопасность
SESSION_SECRET=your_session_secret_change_me
JWT_SECRET=your_jwt_secret_change_me

# База данных (если используется)
DATABASE_URL=sqlite:./data/database.db

# Логирование
LOG_LEVEL=info
LOG_FILE=./logs/app.log
EOF

    # Создаем также .env для разработки
    sudo -u telegram-parser tee "$PROJECT_DIR/.env" > /dev/null << 'EOF'
# Development environment
NODE_ENV=development
PORT=3000
NEXT_PUBLIC_APP_NAME=Telegram Channel Parser
NEXT_PUBLIC_APP_VERSION=1.0.0-dev
EOF

    log "Файлы окружения созданы ✓"
}

# Обновление страницы с правильными стилями
update_main_page() {
    log "Обновление главной страницы с правильными стилями..."
    
    sudo -u telegram-parser tee "$PROJECT_DIR/app/page.tsx" > /dev/null << 'EOF'
'use client'

import { useState, useEffect } from 'react'

interface Settings {
  adminLogin: string
  adminPassword: string
  telegramApiId: string
  telegramApiHash: string
  groqApiKey: string
  isConnected: boolean
}

export default function Home() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [loginForm, setLoginForm] = useState({ login: '', password: '' })
  const [settings, setSettings] = useState<Settings>({
    adminLogin: process.env.NEXT_PUBLIC_ADMIN_LOGIN || 'admin',
    adminPassword: 'admin',
    telegramApiId: '',
    telegramApiHash: '',
    groqApiKey: '',
    isConnected: false
  })
  const [statistics, setStatistics] = useState({
    processed: 0,
    forwarded: 0,
    filtered: 0,
    uptime: 0,
    isRunning: false
  })

  // Загрузка настроек при старте
  useEffect(() => {
    const savedSettings = localStorage.getItem('telegram-parser-settings')
    if (savedSettings) {
      try {
        const parsed = JSON.parse(savedSettings)
        setSettings(prev => ({ ...prev, ...parsed }))
      } catch (error) {
        console.error('Ошибка загрузки настроек:', error)
      }
    }
  }, [])

  const handleLogin = () => {
    if (loginForm.login === settings.adminLogin && loginForm.password === settings.adminPassword) {
      setIsAuthenticated(true)
      localStorage.setItem('telegram-parser-auth', 'true')
    } else {
      alert('Неверный логин или пароль')
    }
  }

  const saveSettings = (newSettings: Partial<Settings>) => {
    const updated = { ...settings, ...newSettings }
    setSettings(updated)
    localStorage.setItem('telegram-parser-settings', JSON.stringify(updated))
  }

  const handleConnect = async () => {
    if (!settings.telegramApiId || !settings.telegramApiHash) {
      alert('Введите API ID и Hash')
      return
    }

    try {
      const response = await fetch('/api/telegram/connect', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          apiId: settings.telegramApiId,
          apiHash: settings.telegramApiHash
        })
      })

      const result = await response.json()
      
      if (result.success) {
        saveSettings({ isConnected: true })
        alert('Подключение успешно!')
      } else {
        alert('Ошибка подключения: ' + result.error)
      }
    } catch (error) {
      alert('Ошибка подключения к серверу')
    }
  }

  const toggleParser = async () => {
    try {
      const action = statistics.isRunning ? 'stop' : 'start'
      const response = await fetch('/api/parser/control', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action })
      })

      const result = await response.json()
      
      if (result.success) {
        setStatistics(prev => ({ ...prev, isRunning: !prev.isRunning }))
        alert(`Парсер ${action === 'start' ? 'запущен' : 'остановлен'}`)
      } else {
        alert('Ошибка: ' + result.error)
      }
    } catch (error) {
      alert('Ошибка управления парсером')
    }
  }

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-md w-full space-y-8">
          <div className="text-center">
            <h2 className="mt-6 text-3xl font-extrabold text-gray-900">
              Telegram Channel Parser
            </h2>
            <p className="mt-2 text-sm text-gray-600">
              Войдите в панель управления
            </p>
          </div>
          <div className="bg-white py-8 px-6 shadow-lg rounded-lg">
            <div className="space-y-6">
              <div>
                <label htmlFor="login" className="block text-sm font-medium text-gray-700">
                  Логин
                </label>
                <input
                  id="login"
                  type="text"
                  className="form-input mt-1"
                  placeholder="Введите логин"
                  value={loginForm.login}
                  onChange={(e) => setLoginForm(prev => ({ ...prev, login: e.target.value }))}
                />
              </div>
              <div>
                <label htmlFor="password" className="block text-sm font-medium text-gray-700">
                  Пароль
                </label>
                <input
                  id="password"
                  type="password"
                  className="form-input mt-1"
                  placeholder="Введите пароль"
                  value={loginForm.password}
                  onChange={(e) => setLoginForm(prev => ({ ...prev, password: e.target.value }))}
                />
              </div>
              <button
                onClick={handleLogin}
                className="btn btn-primary w-full"
              >
                Войти
              </button>
            </div>
            <div className="mt-4 text-center">
              <p className="text-xs text-gray-500">
                По умолчанию: admin / admin
              </p>
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Заголовок */}
      <div className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center">
                <span className="text-white font-bold text-sm">TP</span>
              </div>
              <div>
                <h1 className="text-xl font-semibold text-gray-900">
                  Telegram Channel Parser
                </h1>
                <p className="text-sm text-gray-500">
                  Автоматический парсинг и фильтрация контента
                </p>
              </div>
            </div>
            
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <div className={`indicator-${settings.isConnected ? 'green' : 'red'}`} />
                <span className="text-sm text-gray-600">
                  {settings.isConnected ? 'Подключено' : 'Не подключено'}
                </span>
              </div>
              
              <div className="flex items-center space-x-2">
                <div className={`indicator-${statistics.isRunning ? 'green pulse-slow' : 'red'}`} />
                <span className="text-sm text-gray-600">
                  {statistics.isRunning ? 'Работает' : 'Остановлен'}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Основной контент */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Статистика */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="stat-card">
            <div className="flex items-center justify-between">
              <div>
                <p className="stat-label">Обработано</p>
                <p className="stat-number text-blue-600">{statistics.processed}</p>
              </div>
              <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
                <span className="text-blue-600 text-xl">📊</span>
              </div>
            </div>
          </div>

          <div className="stat-card">
            <div className="flex items-center justify-between">
              <div>
                <p className="stat-label">Переслано</p>
                <p className="stat-number text-green-600">{statistics.forwarded}</p>
              </div>
              <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
                <span className="text-green-600 text-xl">✅</span>
              </div>
            </div>
          </div>

          <div className="stat-card">
            <div className="flex items-center justify-between">
              <div>
                <p className="stat-label">Отфильтровано</p>
                <p className="stat-number text-red-600">{statistics.filtered}</p>
              </div>
              <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
                <span className="text-red-600 text-xl">🚫</span>
              </div>
            </div>
          </div>

          <div className="stat-card">
            <div className="flex items-center justify-between">
              <div>
                <p className="stat-label">Аптайм</p>
                <p className="stat-number text-purple-600">{Math.floor(statistics.uptime / 60)}м</p>
              </div>
              <div className="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center">
                <span className="text-purple-600 text-xl">⏱️</span>
              </div>
            </div>
          </div>
        </div>

        {/* Основные панели */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Подключение к Telegram */}
          <div className="card">
            <div className="card-header">
              <h2 className="text-lg font-semibold text-gray-900">
                Подключение к Telegram
              </h2>
              <p className="text-sm text-gray-600 mt-1">
                Настройка API для работы с Telegram
              </p>
            </div>
            <div className="card-body space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  API ID
                </label>
                <input
                  type="text"
                  className="form-input mt-1"
                  placeholder="Введите API ID"
                  value={settings.telegramApiId}
                  onChange={(e) => saveSettings({ telegramApiId: e.target.value })}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  API Hash
                </label>
                <input
                  type="text"
                  className="form-input mt-1"
                  placeholder="Введите API Hash"
                  value={settings.telegramApiHash}
                  onChange={(e) => saveSettings({ telegramApiHash: e.target.value })}
                />
              </div>
              <button
                onClick={handleConnect}
                className="btn btn-primary w-full"
                disabled={!settings.telegramApiId || !settings.telegramApiHash}
              >
                {settings.isConnected ? 'Переподключиться' : 'Подключиться'}
              </button>
              
              {settings.isConnected && (
                <div className="status-online">
                  ✅ Подключено к Telegram
                </div>
              )}
            </div>
          </div>

          {/* Управление парсером */}
          <div className="card">
            <div className="card-header">
              <h2 className="text-lg font-semibold text-gray-900">
                Управление парсером
              </h2>
              <p className="text-sm text-gray-600 mt-1">
                Запуск и остановка парсинга
              </p>
            </div>
            <div className="card-body space-y-4">
              <button
                onClick={toggleParser}
                className={`btn w-full ${statistics.isRunning ? 'btn-danger' : 'btn-success'}`}
                disabled={!settings.isConnected}
              >
                {statistics.isRunning ? '⏹️ Остановить парсер' : '▶️ Запустить парсер'}
              </button>
              
              <button
                className="btn btn-secondary w-full"
                onClick={() => alert('Логи парсера (в разработке)')}
              >
                📋 Просмотр логов
              </button>
              
              <button
                className="btn btn-secondary w-full"
                onClick={() => {
                  setStatistics({ processed: 0, forwarded: 0, filtered: 0, uptime: 0, isRunning: false })
                  alert('Статистика сброшена')
                }}
              >
                🔄 Сбросить статистику
              </button>
            </div>
          </div>

          {/* AI Фильтрация */}
          <div className="card">
            <div className="card-header">
              <h2 className="text-lg font-semibold text-gray-900">
                AI Фильтрация
              </h2>
              <p className="text-sm text-gray-600 mt-1">
                Настройка искусственного интеллекта
              </p>
            </div>
            <div className="card-body space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Groq API Key
                </label>
                <input
                  type="password"
                  className="form-input mt-1"
                  placeholder="Введите Groq API ключ"
                  value={settings.groqApiKey}
                  onChange={(e) => saveSettings({ groqApiKey: e.target.value })}
                />
              </div>
              
              <button
                className="btn btn-primary w-full"
                disabled={!settings.groqApiKey}
                onClick={() => alert('Тест AI фильтра (в разработке)')}
              >
                🧠 Тестировать AI
              </button>
              
              <div className="text-xs text-gray-500">
                <p>Получите бесплатный ключ на:</p>
                <a 
                  href="https://console.groq.com" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="text-blue-600 hover:underline"
                >
                  console.groq.com
                </a>
              </div>
            </div>
          </div>
        </div>

        {/* Информационная панель */}
        <div className="mt-8 card">
          <div className="card-header">
            <h2 className="text-lg font-semibold text-gray-900">
              Информация о системе
            </h2>
          </div>
          <div className="card-body">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 text-sm">
              <div>
                <span className="font-medium text-gray-700">Версия:</span>
                <span className="ml-2 text-gray-900">1.0.0</span>
              </div>
              <div>
                <span className="font-medium text-gray-700">Статус:</span>
                <span className={`ml-2 ${statistics.isRunning ? 'text-green-600' : 'text-red-600'}`}>
                  {statistics.isRunning ? 'Активен' : 'Неактивен'}
                </span>
              </div>
              <div>
                <span className="font-medium text-gray-700">Подключение:</span>
                <span className={`ml-2 ${settings.isConnected ? 'text-green-600' : 'text-red-600'}`}>
                  {settings.isConnected ? 'Подключено' : 'Не подключено'}
                </span>
              </div>
              <div>
                <span className="font-medium text-gray-700">Обновлено:</span>
                <span className="ml-2 text-gray-900">{new Date().toLocaleString()}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
EOF

    log "Главная страница обновлена ✓"
}

# Создание API для работы с переменными окружения
create_env_api() {
    log "Создание API для работы с переменными окружения..."
    
    # API для получения настроек
    sudo mkdir -p "$PROJECT_DIR/app/api/settings"
    sudo -u telegram-parser tee "$PROJECT_DIR/app/api/settings/route.ts" > /dev/null << 'EOF'
import { NextRequest, NextResponse } from 'next/server'

export async function GET() {
  try {
    // Возвращаем только публичные переменные
    const settings = {
      appName: process.env.NEXT_PUBLIC_APP_NAME || 'Telegram Channel Parser',
      appVersion: process.env.NEXT_PUBLIC_APP_VERSION || '1.0.0',
      adminLogin: process.env.ADMIN_LOGIN || 'admin',
      // Не возвращаем пароли и секретные ключи
      hasApiId: !!process.env.TELEGRAM_API_ID,
      hasApiHash: !!process.env.TELEGRAM_API_HASH,
      hasGroqKey: !!process.env.GROQ_API_KEY,
    }

    return NextResponse.json({
      success: true,
      settings
    })
  } catch (error) {
    console.error('Ошибка получения настроек:', error)
    return NextResponse.json(
      { success: false, error: 'Не удалось получить настройки' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    const { key, value } = await request.json()
    
    // Здесь можно добавить логику сохранения настроек
    // Пока что просто возвращаем успех
    
    return NextResponse.json({
      success: true,
      message: 'Настройки сохранены'
    })
  } catch (error) {
    console.error('Ошибка сохранения настроек:', error)
    return NextResponse.json(
      { success: false, error: 'Не удалось сохранить настройки' },
      { status: 500 }
    )
  }
}
EOF

    log "API настроек создан ✓"
}

# Обновление next.config.js для работы с переменными окружения
update_next_config() {
    log "Обновление конфигурации Next.js..."
    
    sudo -u telegram-parser tee "$PROJECT_DIR/next.config.js" > /dev/null << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    appDir: true,
  },
  env: {
    // Серверные переменные окружения
    TELEGRAM_API_ID: process.env.TELEGRAM_API_ID,
    TELEGRAM_API_HASH: process.env.TELEGRAM_API_HASH,
    GROQ_API_KEY: process.env.GROQ_API_KEY,
    ADMIN_LOGIN: process.env.ADMIN_LOGIN,
    ADMIN_PASSWORD: process.env.ADMIN_PASSWORD,
  },
  // Публичные переменные (доступны в браузере)
  publicRuntimeConfig: {
    appName: process.env.NEXT_PUBLIC_APP_NAME,
    appVersion: process.env.NEXT_PUBLIC_APP_VERSION,
  },
  // Серверные переменные (только на сервере)
  serverRuntimeConfig: {
    telegramApiId: process.env.TELEGRAM_API_ID,
    telegramApiHash: process.env.TELEGRAM_API_HASH,
    groqApiKey: process.env.GROQ_API_KEY,
    adminLogin: process.env.ADMIN_LOGIN,
    adminPassword: process.env.ADMIN_PASSWORD,
  }
}

module.exports = nextConfig
EOF

    log "Конфигурация Next.js обновлена ✓"
}

# Главная функция
main() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           Исправление стилей и переменных окружения           ║"
    echo "║              Telegram Channel Parser                          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo
    
    if [[ ! -d "$PROJECT_DIR" ]]; then
        error "Директория проекта не найдена: $PROJECT_DIR"
        exit 1
    fi
    
    cd "$PROJECT_DIR"
    
    fix_styles
    create_env_file
    update_main_page
    create_env_api
    update_next_config
    
    echo
    log "✅ Исправления применены успешно!"
    echo
    info "Что исправлено:"
    info "  ✓ Стили - убран белый текст на белом фоне"
    info "  ✓ Добавлены правильные CSS классы"
    info "  ✓ Создан файл .env.local с переменными"
    info "  ✓ Обновлена главная страница с лучшим дизайном"
    info "  ✓ Добавлен API для работы с настройками"
    info "  ✓ Настроена конфигурация Next.js"
    echo
    warning "Теперь нужно пересобрать и перезапустить приложение:"
    warning "  telegram-parser stop"
    warning "  cd $PROJECT_DIR && sudo -u telegram-parser npm run build"
    warning "  telegram-parser start"
    echo
    info "После перезапуска:"
    info "  • Текст будет читаемым (черный на белом)"
    info "  • Настройки будут сохраняться"
    info "  • Интерфейс станет более удобным"
}

# Запуск
main "$@"
