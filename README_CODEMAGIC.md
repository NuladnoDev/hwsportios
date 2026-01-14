# Инструкция по сборке Unsigned iOS App (.ipa) через Codemagic (для Windows/Linux пользователей)

Этот документ объясняет, как настроить `codemagic.yaml`, чтобы собрать iOS-приложение без платного аккаунта Apple Developer и без Mac, для последующей установки через Sideloadly/AltStore.

## Основная концепция
Для сборки на Codemagic обычно требуются сертификаты и профили. Чтобы это обойти, мы:
1. Создаем пустой проект Xcode прямо в процессе сборки через Ruby-скрипт.
2. Отключаем подпись кода (`CODE_SIGNING_ALLOWED=NO`).
3. Создаем структуру `.ipa` вручную через упаковку папки `Payload`.

## Ключевые настройки в codemagic.yaml

### 1. Отключение интеграций
В начале файла **НЕ должно быть** секции `integrations` с `app_store_connect`, иначе билд упадет, требуя API ключи.

### 2. Скрипт подготовки проекта (Ruby + xcodeproj)
Xcodebuild не умеет собирать "просто файлы", ему нужен файл проекта `.xcodeproj`. Мы создаем его динамически:
```ruby
gem install xcodeproj
ruby -e "
  require 'xcodeproj'
  project = Xcodeproj::Project.new('Name.xcodeproj')
  target = project.new_target(:application, 'Name', :ios, '15.0')
  # Добавляем файлы кода и ресурсов
  target.add_file_references([project.new_file('App.swift')])
  
  target.build_configurations.each do |config|
    s = config.build_settings
    s['CODE_SIGNING_ALLOWED'] = 'NO'
    s['CODE_SIGNING_REQUIRED'] = 'NO'
    s['CODE_SIGN_IDENTITY'] = ''
    s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.your.bundle'
  end
  # ВАЖНО: Создаем схему, иначе xcodebuild ее не найдет
  scheme = Xcodeproj::XCScheme.new
  scheme.add_build_target(target)
  scheme.save_as(project.path, 'Name', true)
  project.save
"
```

### 3. Команда сборки
Используйте флаги для полного отключения подписи:
```bash
xcodebuild build \
  -project Name.xcodeproj \
  -scheme Name \
  -sdk iphoneos \
  -configuration Release \
  -derivedDataPath build_output \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

### 4. Ручная упаковка в .ipa
Codemagic не создаст `.ipa` автоматически без подписи. Делаем это сами:
```bash
# 1. Находим скомпилированное приложение .app
APP_PATH=$(find build_output -name "*.app" -type d | head -n 1)
# 2. Создаем структуру для Sideloadly
mkdir -p Payload
cp -R "$APP_PATH" Payload/
# 3. Архивируем в .ipa
zip -r YourApp.ipa Payload
```

## Требования к файлам
- **Info.plist**: Должен существовать и содержать `CFBundleExecutable`, иначе Sideloadly не увидит приложение.
- **Assets**: Если нет `Assets.car`, приложение может не иметь иконки, но будет работать.

## Почему это работает?
Sideloadly и AltStore сами подписывают приложение твоим бесплатным Apple ID при установке. Им нужен только корректно собранный бинарный файл под архитектуру `arm64`.
