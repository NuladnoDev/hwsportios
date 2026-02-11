import SwiftUI
import AVFoundation
import AudioToolbox

// MARK: - Models
enum AppLanguage: String, Codable {
    case russian = "RU"
    case english = "EN"
}

enum StageType: String, Codable {
    case warmup, run, walk, cooldown
    
    var color: Color {
        switch self {
        case .warmup: return .yellow
        case .run: return .red
        case .walk: return .blue
        case .cooldown: return .green
        }
    }
    
    func label(for lang: AppLanguage) -> String {
        switch self {
        case .warmup: return lang == .russian ? "ПОДГОТОВКА" : "WARMUP"
        case .run: return lang == .russian ? "ИНТЕНСИВ" : "INTENSE"
        case .walk: return lang == .russian ? "ОТДЫХ" : "REST"
        case .cooldown: return lang == .russian ? "ЗАМИНКА" : "COOLDOWN"
        }
    }
}

struct WorkoutStage: Identifiable, Codable {
    var id = UUID()
    var name: String
    var duration: Int // в секундах
    var speed: String
    var type: StageType
}

// MARK: - App State
class WorkoutManager: ObservableObject {
    @Published var language: AppLanguage = .russian
    
    @Published var stages: [WorkoutStage] = []
    
    @Published var currentStageIndex = 0
    @Published var timeLeft = 0
    @Published var isActive = false
    @Published var isFinished = false
    
    // Для модальных окон
    @Published var showingAddStage = false
    @Published var showingSettings = false
    @Published var editingStage: WorkoutStage?
    
    private var timer: Timer?
    
    init() {
        setupDefaultStages()
    }
    
    func setupDefaultStages() {
        if language == .russian {
            stages = [
                WorkoutStage(name: "Разминка", duration: 300, speed: "5.0", type: .warmup),
                WorkoutStage(name: "Бег", duration: 60, speed: "6.5", type: .run),
                WorkoutStage(name: "Ходьба", duration: 120, speed: "5.0", type: .walk),
                WorkoutStage(name: "Заминка", duration: 300, speed: "4.5", type: .cooldown)
            ]
        } else {
            stages = [
                WorkoutStage(name: "Warmup", duration: 300, speed: "5.0", type: .warmup),
                WorkoutStage(name: "Run", duration: 60, speed: "6.5", type: .run),
                WorkoutStage(name: "Walk", duration: 120, speed: "5.0", type: .walk),
                WorkoutStage(name: "Cooldown", duration: 300, speed: "4.5", type: .cooldown)
            ]
        }
        reset()
    }
    
    func t(_ ru: String, _ en: String) -> String {
        language == .russian ? ru : en
    }
    
    func start() {
        if stages.isEmpty { return }
        timeLeft = stages[currentStageIndex].duration
        isActive = true
        runTimer()
    }
    
    func toggle() {
        if stages.isEmpty { return }
        isActive.toggle()
        if isActive { runTimer() } else { timer?.invalidate() }
    }
    
    func skipNext() {
        if currentStageIndex < stages.count - 1 {
            currentStageIndex += 1
            timeLeft = stages[currentStageIndex].duration
        }
    }
    
    func skipPrev() {
        if currentStageIndex > 0 {
            currentStageIndex -= 1
            timeLeft = stages[currentStageIndex].duration
        }
    }
    
    func reset() {
        isActive = false
        isFinished = false
        currentStageIndex = 0
        if !stages.isEmpty {
            timeLeft = stages[0].duration
        }
        timer?.invalidate()
    }
    
    func addStage(_ stage: WorkoutStage) {
        stages.append(stage)
    }
    
    func updateStage(_ stage: WorkoutStage) {
        if let index = stages.firstIndex(where: { $0.id == stage.id }) {
            stages[index] = stage
        }
    }
    
    private func runTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.timeLeft > 0 {
                self.timeLeft -= 1
            } else {
                self.nextStage()
            }
        }
    }
    
    private func nextStage() {
        if currentStageIndex < stages.count - 1 {
            currentStageIndex += 1
            timeLeft = stages[currentStageIndex].duration
            playNotificationSound()
        } else {
            isActive = false
            isFinished = true
            timer?.invalidate()
        }
    }
    
    private func playNotificationSound() {
        AudioServicesPlaySystemSound(1005) // Стандартный звук уведомления iOS
    }
}

// MARK: - Views
struct ContentView: View {
    @StateObject var manager = WorkoutManager()
    @State private var selectedTab = 0
    @Namespace private var animation
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Контент
            Group {
                if selectedTab == 0 {
                    BuilderView(manager: manager)
                } else {
                    TimerView(manager: manager)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Новая навигация в стиле Telegram (Liquid Glass iOS 16+)
            HStack(spacing: 0) {
                ForEach(0..<2) { index in
                    let isSelected = selectedTab == index
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: index == 0 ? (isSelected ? "list.bullet.rectangle.portrait.fill" : "list.bullet.rectangle.portrait") : (isSelected ? "timer" : "timer"))
                                .font(.system(size: 20, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(isSelected ? .blue : .secondary)
                            
                            Text(index == 0 ? manager.t("План", "Plan") : manager.t("Таймер", "Timer"))
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .blue : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Color.blue.opacity(0.12))
                                    .matchedGeometryEffect(id: "TAB_BLOB", in: animation)
                                    .frame(width: 80, height: 50)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 15)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    .overlay {
                        Capsule()
                            .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 0.5)
                    }
            }
            .padding(.horizontal, 50)
            .padding(.bottom, 20)
        }
        .preferredColorScheme(.dark)
    }
}

// Удаляем старый NavButton, так как логика теперь внутри ForEach

struct TimerView: View {
    @ObservedObject var manager: WorkoutManager
    
    var body: some View {
        ZStack(alignment: .top) {
            // Контент таймера (центрированный)
            VStack {
                Spacer()
                
                if manager.stages.isEmpty {
                    Text(manager.t("Добавьте этапы в плане", "Add stages in Plan"))
                        .foregroundColor(.secondary)
                } else if manager.isFinished {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        Text(manager.t("ГОТОВО!", "DONE!")).bold()
                            .font(.largeTitle)
                    }
                } else {
                    let stage = manager.stages[min(manager.currentStageIndex, manager.stages.count - 1)]
                    
                    VStack(spacing: 8) {
                        Text(stage.type.label(for: manager.language)).bold()
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(stage.type.color.opacity(0.2))
                            .foregroundColor(stage.type.color)
                            .clipShape(Capsule())
                        
                        Text(stage.name).bold()
                            .font(.title2)
                    }
                    
                    Text(formatTime(manager.timeLeft))
                        .font(.system(size: 100, weight: .black, design: .monospaced))
                        .padding(.vertical, 20)
                    
                    HStack {
                        Image(systemName: "figure.walk")
                        Text("\(stage.speed) " + manager.t("КМ/Ч", "KM/H")).bold()
                    }
                    .font(.title)
                    .foregroundColor(.secondary)
                    
                    HStack(spacing: 40) {
                        Button(action: manager.skipPrev) {
                            Image(systemName: "backward.fill")
                                .font(.title)
                        }
                        
                        Button(action: manager.toggle) {
                            Image(systemName: manager.isActive ? "pause.fill" : "play.fill")
                                .font(.system(size: 40))
                                .frame(width: 90, height: 90)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .clipShape(Circle())
                        }
                        
                        Button(action: manager.skipNext) {
                            Image(systemName: "forward.fill")
                                .font(.title)
                        }
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Кнопки управления сверху (Liquid Glass iOS 26)
            HStack {
                Button(action: manager.reset) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .bold))
                        Text(manager.t("Сброс", "Reset"))
                            .font(.system(size: 14, weight: .bold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial)
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        }
                    )
                }
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                Spacer()
                
                Button(action: { manager.showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .bold))
                        .padding(12)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            }
                        )
                }
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .sheet(isPresented: $manager.showingSettings) {
            SettingsView(manager: manager)
        }
    }
    
    func formatTime(_ s: Int) -> String {
        "\(s / 60):\(String(format: "%02d", s % 60))"
    }
}

struct BuilderView: View {
    @ObservedObject var manager: WorkoutManager
    
    var body: some View {
        NavigationView {
            List {
                ForEach(manager.stages) { stage in
                    Button(action: {
                        manager.editingStage = stage
                    }) {
                        HStack {
                            Circle().fill(stage.type.color).frame(width: 10)
                            VStack(alignment: .leading) {
                                Text(stage.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("\(stage.duration / 60) " + manager.t("мин", "min") + " • \(stage.speed) " + manager.t("км/ч", "km/h"))
                                    .font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete { manager.stages.remove(atOffsets: $0) }
                .onMove { manager.stages.move(fromOffsets: $0, toOffset: $1) }
                
                // Карточка про воду
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            Text(manager.t("Пейте воду", "Drink Water")).bold()
                                .font(.headline)
                        }
                        
                        Text(manager.t("Не забывайте пить небольшими глотками за 15-20 минут до начала и во время тренировки, чтобы избежать обезвоживания.", "Don't forget to drink in small sips 15-20 minutes before and during your workout to avoid dehydration."))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(manager.t("Тренировка", "Workout"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { /* Пустышка */ }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text(manager.t("Попросить ИИ", "Ask AI")).bold()
                        }
                        .font(.caption)
                        .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        EditButton()
                        Button(action: { manager.showingAddStage = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $manager.showingAddStage) {
                StageEditorView(manager: manager)
            }
            .sheet(item: $manager.editingStage) { stage in
                StageEditorView(manager: manager, stageToEdit: stage)
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var manager: WorkoutManager
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text(manager.t("ЯЗЫК", "LANGUAGE"))) {
                    Button(action: {
                        manager.language = .russian
                        manager.setupDefaultStages()
                    }) {
                        HStack {
                            Text("Русский")
                            Spacer()
                            if manager.language == .russian {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: {
                        manager.language = .english
                        manager.setupDefaultStages()
                    }) {
                        HStack {
                            Text("English")
                            Spacer()
                            if manager.language == .english {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle(manager.t("Настройки", "Settings"))
            .navigationBarItems(trailing: Button(manager.t("Готово", "Done")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct StageEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var manager: WorkoutManager
    
    @State private var name: String
    @State private var minutes: Int
    @State private var speed: String
    @State private var type: StageType
    
    var stageToEdit: WorkoutStage?
    
    init(manager: WorkoutManager, stageToEdit: WorkoutStage? = nil) {
        self.manager = manager
        self.stageToEdit = stageToEdit
        
        _name = State(initialValue: stageToEdit?.name ?? "Новый этап")
        _minutes = State(initialValue: (stageToEdit?.duration ?? 60) / 60)
        _speed = State(initialValue: stageToEdit?.speed ?? "5.0")
        _type = State(initialValue: stageToEdit?.type ?? .walk)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(manager.t("ОСНОВНОЕ", "GENERAL"))) {
                    TextField(manager.t("Название", "Name"), text: $name)
                    
                    Picker(manager.t("Тип", "Type"), selection: $type) {
                        Text(manager.t("Подготовка", "Warmup")).tag(StageType.warmup)
                        Text(manager.t("Интенсив", "Intense")).tag(StageType.run)
                        Text(manager.t("Отдых", "Rest")).tag(StageType.walk)
                        Text(manager.t("Заминка", "Cooldown")).tag(StageType.cooldown)
                    }
                }
                
                Section(header: Text(manager.t("ПАРАМЕТРЫ", "PARAMETERS"))) {
                    Stepper(manager.t("Длительность: \(minutes) мин", "Duration: \(minutes) min"), value: $minutes, in: 1...60)
                    
                    HStack {
                        Text(manager.t("Скорость (км/ч)", "Speed (km/h)"))
                        Spacer()
                        TextField("5.0", text: $speed)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle(stageToEdit == nil ? manager.t("Добавить", "Add") : manager.t("Изменить", "Edit"))
            .navigationBarItems(
                leading: Button(manager.t("Отмена", "Cancel")) {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(action: {
                    let newStage = WorkoutStage(
                        id: stageToEdit?.id ?? UUID(),
                        name: name,
                        duration: minutes * 60,
                        speed: speed,
                        type: type
                    )
                    
                    if stageToEdit == nil {
                        manager.addStage(newStage)
                    } else {
                        manager.updateStage(newStage)
                    }
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(manager.t("Готово", "Done")).bold()
                }
            )
        }
    }
}

@main
struct TreadmillApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
