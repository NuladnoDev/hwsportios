# SwiftUI UI Style Guide: Liquid Glass & iOS Components

Этот гайд описывает, как реализовать визуальные эффекты "матового стекла" (Liquid Glass) и специфические компоненты (капсулы, оверлеи), использованные в приложении Treadmill.

## 1. Эффект Liquid Glass (Матовое стекло)
Для создания эффекта размытия фона под элементами управления используется системный материал `.ultraThinMaterial`.

### Базовая реализация:
```swift
// Для кнопок и панелей
.background(.ultraThinMaterial)
.cornerRadius(10) // или .clipShape(RoundedRectangle(cornerRadius: 12))
```

### Пример из TimerView (кнопки сверху):
```swift
HStack(spacing: 6) {
    Image(systemName: "arrow.counterclockwise")
    Text("Сброс").bold()
}
.font(.footnote)
.padding(.horizontal, 12)
.padding(.vertical, 8)
.background(.ultraThinMaterial) // Тот самый Liquid Glass
.cornerRadius(10)
```

## 2. Элемент "Капля" (Capsule Label)
Используется для отображения типа этапа (Разминка, Бег и т.д.) поверх контента.

### Реализация:
```swift
Text(stage.type.label).bold()
    .font(.caption)
    .padding(.horizontal, 12)
    .padding(.vertical, 4)
    .background(stage.type.color.opacity(0.2)) // Полупрозрачный цвет фона
    .foregroundColor(stage.type.color)          // Насыщенный цвет текста
    .clipShape(Capsule())                      // Форма идеальной капли/капсулы
```

## 3. Навигация и Табы (Liquid Design)
Приложение использует системный `TabView`, который на iOS автоматически применяет эффект размытия к нижней панели навигации.

### Структура:
```swift
TabView {
    TimerView(manager: manager)
        .tabItem {
            Label("Таймер", systemImage: "timer")
        }
    
    BuilderView(manager: manager)
        .tabItem {
            Label("План", systemImage: "list.bullet")
        }
}
.accentColor(.blue) // Цвет активной иконки
```

## 4. Оверлеи и Карточки (Инфо-блоки)
Для карточек (например, совет про воду) используется стандартная группировка `Section` внутри `Form` или `List`, что дает нативный iOS вид.

### Специфика "Пейте воду":
```swift
VStack(alignment: .leading, spacing: 12) {
    HStack {
        Image(systemName: "drop.fill") // Иконка капли
            .foregroundColor(.blue)
        Text("Пейте воду").bold()
    }
    Text("Описание...")
        .font(.subheadline)
        .foregroundColor(.secondary)
}
.padding(.vertical, 8)
```

## Важные правила для совместимости (iOS 15+):
1. **Никогда** не применять `.bold()` к контейнерам (`Label`, `HStack`, `VStack`). Только к конечному `Text`.
2. **Материалы**: `.ultraThinMaterial` доступен начиная с iOS 15. Он автоматически подстраивается под светлую и темную темы.
3. **Иконки**: Использовать только системные `SF Symbols` через `Image(systemName: "...")`.
