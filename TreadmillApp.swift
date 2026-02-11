import SwiftUI
import AVFoundation
import AudioToolbox

// MARK: - Models
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
    
    var label: String {
        switch self {
        case .warmup: return "ПОДГОТОВКА"
        case .run: return "ИНТЕНСИВ"
        case .walk: return "ОТДЫХ"
        case .cooldown: return "ЗАМИНКА"
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
    @Published var stages: [WorkoutStage] = [
        WorkoutStage(name: "Разминка", duration: 300, speed: "5.0", type: .warmup),
        WorkoutStage(name: "Бег", duration: 60, speed: "6.5", type: .run),
        WorkoutStage(name: "Ходьба", duration: 120, speed: "5.0", type: .walk),
        WorkoutStage(name: "Заминка", duration: 300, speed: "4.5", type: .cooldown)
    ]
    
    @Published var currentStageIndex = 0
    @Published var timeLeft = 0
    @Published var isActive = false
    @Published var isFinished = false
    
    // Для модального окна
    @Published var showingAddStage = false
    @Published var editingStage: WorkoutStage?
    
    private var timer: Timer?
    
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
            
            // Кастомная навигация (Liquid Glass iOS 26)
            ZStack {
                // Фоновое свечение (Glow)
                Capsule()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 120, height: 40)
                    .blur(radius: 30)
                    .offset(x: selectedTab == 0 ? -40 : 40)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedTab)
                
                // Основная панель
                HStack(spacing: 8) {
                    NavButton(title: "План", icon: "list.bullet.rectangle.portrait", isSelected: selectedTab == 0, animation: animation) {
                        selectedTab = 0
                    }
                    
                    NavButton(title: "Таймер", icon: "timer", isSelected: selectedTab == 1, animation: animation) {
                        selectedTab = 1
                    }
                }
                .padding(.horizontal, 8)
                .frame(width: 220, height: 64)
                .background(
                    ZStack {
                        // Основной материал стекла
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(.ultraThinMaterial)
                        
                        // Внутренний блик
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .white.opacity(0.1), .clear, .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            }
            .padding(.bottom, 24)
        }
        .preferredColorScheme(.dark)
    }
}

struct NavButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var animation: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? icon + ".fill" : icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                    .symbolRenderingMode(.hierarchical)
                
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? .blue : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.blue.opacity(0.12))
                            .matchedGeometryEffect(id: "tab", in: animation)
                    }
                }
            )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

struct TimerView: View {
    @ObservedObject var manager: WorkoutManager
    
    var body: some View {
        ZStack(alignment: .top) {
            // Контент таймера (центрированный)
            VStack {
                Spacer()
                
                if manager.stages.isEmpty {
                    Text("Добавьте этапы в плане")
                        .foregroundColor(.secondary)
                } else if manager.isFinished {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        Text("ГОТОВО!").bold()
                            .font(.largeTitle)
                    }
                } else {
                    let stage = manager.stages[min(manager.currentStageIndex, manager.stages.count - 1)]
                    
                    VStack(spacing: 8) {
                        Text(stage.type.label).bold()
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
                        Text("\(stage.speed) КМ/Ч").bold()
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
                        Text("Сброс")
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
                
                Button(action: { /* Настройки */ }) {
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
                                Text("\(stage.duration / 60) мин • \(stage.speed) км/ч")
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
                            Text("Пейте воду").bold()
                                .font(.headline)
                        }
                        
                        Text("Не забывайте пить небольшими глотками за 15-20 минут до начала и во время тренировки, чтобы избежать обезвоживания.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Тренировка")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { /* Пустышка */ }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Попросить ИИ").bold()
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
                Section(header: Text("ОСНОВНОЕ")) {
                    TextField("Название", text: $name)
                    
                    Picker("Тип", selection: $type) {
                        Text("Подготовка").tag(StageType.warmup)
                        Text("Интенсив").tag(StageType.run)
                        Text("Отдых").tag(StageType.walk)
                        Text("Заминка").tag(StageType.cooldown)
                    }
                }
                
                Section(header: Text("ПАРАМЕТРЫ")) {
                    Stepper("Длительность: \(minutes) мин", value: $minutes, in: 1...60)
                    
                    HStack {
                        Text("Скорость (км/ч)")
                        Spacer()
                        TextField("5.0", text: $speed)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle(stageToEdit == nil ? "Добавить" : "Изменить")
            .navigationBarItems(
                leading: Button("Отмена") {
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
                    Text("Готово").bold()
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
