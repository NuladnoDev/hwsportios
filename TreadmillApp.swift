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
    
    private var timer: Timer?
    
    func start() {
        timeLeft = stages[currentStageIndex].duration
        isActive = true
        runTimer()
    }
    
    func toggle() {
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
    
    func addStage() {
        let newStage = WorkoutStage(name: "Новый этап", duration: 60, speed: "5.0", type: .walk)
        stages.append(newStage)
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
                ForEach($manager.stages) { $stage in
                    HStack {
                        Circle().fill(stage.type.color).frame(width: 10)
                        VStack(alignment: .leading) {
                            TextField("Название", text: $stage.name)
                                .font(.headline)
                            Text("\(stage.duration / 60) мин • \(stage.speed) км/ч")
                                .font(.subheadline).foregroundColor(.secondary)
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
                            Text("Попросить ИИ")
                        }
                        .font(.caption).bold()
                        .padding(6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        EditButton()
                        Button(action: manager.addStage) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
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
