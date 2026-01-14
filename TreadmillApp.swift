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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            BuilderView(manager: manager)
                .tabItem {
                    Label("План", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(0)
            
            TimerView(manager: manager)
                .tabItem {
                    Label("Таймер", systemImage: "timer")
                }
                .tag(1)
        }
        .preferredColorScheme(.dark)
    }
}

struct TimerView: View {
    @ObservedObject var manager: WorkoutManager
    
    var body: some View {
        VStack(spacing: 40) {
            if manager.stages.isEmpty {
                Text("Добавьте этапы в плане")
                    .foregroundColor(.secondary)
            } else if manager.isFinished {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    Text("ГОТОВО!")
                        .font(.largeTitle).bold()
                }
            } else {
                let stage = manager.stages[min(manager.currentStageIndex, manager.stages.count - 1)]
                
                VStack(spacing: 8) {
                    Text(stage.type.label)
                        .font(.caption).bold()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(stage.type.color.opacity(0.2))
                        .foregroundColor(stage.type.color)
                        .clipShape(Capsule())
                    
                    Text(stage.name)
                        .font(.title2).bold()
                }
                
                Text(formatTime(manager.timeLeft))
                    .font(.system(size: 100, weight: .black, design: .monospaced))
                
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
                            .font(.system(size: 50))
                            .frame(width: 100, height: 100)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .clipShape(Circle())
                    }
                    
                    Button(action: manager.skipNext) {
                        Image(systemName: "forward.fill")
                            .font(.title)
                    }
                }
            }
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
                        .padding(6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
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
