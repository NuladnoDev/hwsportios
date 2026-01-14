import React, { useState, useEffect, useCallback } from 'react';
import { 
  Play, 
  Pause, 
  RotateCcw, 
  ChevronRight, 
  ChevronLeft, 
  Plus, 
  Trash2, 
  LayoutGrid, 
  Timer as TimerIcon,
  Settings,
  Flame,
  Wind,
  Move
} from 'lucide-react';

interface Stage {
  id: string;
  name: string;
  duration: number; // в секундах
  speed: string;
  type: 'walk' | 'run' | 'cooldown' | 'warmup';
}

const DEFAULT_STAGES: Stage[] = [
  { id: '1', name: 'Разминка', duration: 300, speed: '5.0', type: 'warmup' },
  { id: '2', name: 'Бег', duration: 60, speed: '6.5', type: 'run' },
  { id: '3', name: 'Ходьба', duration: 120, speed: '5.0', type: 'walk' },
  { id: '4', name: 'Заминка', duration: 300, speed: '4.5', type: 'cooldown' },
];

function App() {
  const [stages, setStages] = useState<Stage[]>(() => {
    const saved = localStorage.getItem('workout_stages');
    return saved ? JSON.parse(saved) : DEFAULT_STAGES;
  });

  const [mode, setMode] = useState<'builder' | 'timer'>('timer');
  const [currentStageIndex, setCurrentStageIndex] = useState(0);
  const [timeLeft, setTimeLeft] = useState(stages[0]?.duration || 0);
  const [isActive, setIsActive] = useState(false);
  const [isFinished, setIsFinished] = useState(false);

  // Сохранение при изменении
  useEffect(() => {
    localStorage.setItem('workout_stages', JSON.stringify(stages));
  }, [stages]);

  const currentStage = stages[currentStageIndex];

  const playSound = useCallback((frequency: number) => {
    try {
      const audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
      const oscillator = audioCtx.createOscillator();
      const gainNode = audioCtx.createGain();

      oscillator.connect(gainNode);
      gainNode.connect(audioCtx.destination);

      oscillator.type = 'sine';
      oscillator.frequency.setValueAtTime(frequency, audioCtx.currentTime);
      
      gainNode.gain.setValueAtTime(0, audioCtx.currentTime);
      gainNode.gain.linearRampToValueAtTime(0.1, audioCtx.currentTime + 0.01);
      gainNode.gain.exponentialRampToValueAtTime(0.0001, audioCtx.currentTime + 0.3);

      oscillator.start();
      oscillator.stop(audioCtx.currentTime + 0.3);
    } catch (e) {
      console.error('Audio error:', e);
    }
  }, []);

  useEffect(() => {
    let interval: number | undefined;

    if (isActive && timeLeft > 0) {
      interval = setInterval(() => {
        setTimeLeft((prev) => prev - 1);
      }, 1000);
    } else if (isActive && timeLeft === 0) {
      if (currentStageIndex < stages.length - 1) {
        playSound(880); // Писк при переключении
        setCurrentStageIndex((prev) => prev + 1);
        setTimeLeft(stages[currentStageIndex + 1].duration);
      } else {
        setIsActive(false);
        setIsFinished(true);
        playSound(440);
        setTimeout(() => playSound(440), 400);
      }
    }

    return () => clearInterval(interval);
  }, [isActive, timeLeft, currentStageIndex, stages, playSound]);

  const toggleTimer = () => setIsActive(!isActive);
  
  const resetTimer = () => {
    setIsActive(false);
    setIsFinished(false);
    setCurrentStageIndex(0);
    setTimeLeft(stages[0]?.duration || 0);
  };

  const skipNext = () => {
    if (currentStageIndex < stages.length - 1) {
      setCurrentStageIndex(prev => prev + 1);
      setTimeLeft(stages[currentStageIndex + 1].duration);
    }
  };

  const skipPrev = () => {
    if (currentStageIndex > 0) {
      setCurrentStageIndex(prev => prev - 1);
      setTimeLeft(stages[currentStageIndex - 1].duration);
    }
  };

  const addStage = (type: Stage['type']) => {
    const newStage: Stage = {
      id: Math.random().toString(36).substr(2, 9),
      name: type === 'run' ? 'Бег' : type === 'walk' ? 'Ходьба' : type === 'warmup' ? 'Разминка' : 'Заминка',
      duration: 60,
      speed: '5.0',
      type
    };
    setStages([...stages, newStage]);
  };

  const removeStage = (id: string) => {
    setStages(stages.filter(s => s.id !== id));
  };

  const updateStage = (id: string, updates: Partial<Stage>) => {
    setStages(stages.map(s => s.id === id ? { ...s, ...updates } : s));
  };

  const moveStage = (index: number, direction: 'up' | 'down') => {
    const newStages = [...stages];
    const targetIndex = direction === 'up' ? index - 1 : index + 1;
    if (targetIndex >= 0 && targetIndex < stages.length) {
      [newStages[index], newStages[targetIndex]] = [newStages[targetIndex], newStages[index]];
      setStages(newStages);
    }
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const getStageColor = (type: Stage['type']) => {
    switch (type) {
      case 'run': return 'text-[#FF3B30]';
      case 'walk': return 'text-[#007AFF]';
      case 'warmup': return 'text-[#FFCC00]';
      case 'cooldown': return 'text-[#34C759]';
      default: return 'text-white';
    }
  };

  const getStageBg = (type: Stage['type']) => {
    switch (type) {
      case 'run': return 'bg-[#FF3B30]/10';
      case 'walk': return 'bg-[#007AFF]/10';
      case 'warmup': return 'bg-[#FFCC00]/10';
      case 'cooldown': return 'bg-[#34C759]/10';
      default: return 'bg-white/10';
    }
  };

  return (
    <div className="min-h-screen bg-black text-white font-[-apple-system,BlinkMacSystemFont,sans-serif] select-none touch-none overflow-hidden flex flex-col">
      {/* iOS Status Bar Placeholder */}
      <div className="h-12 w-full bg-black/80 backdrop-blur-xl fixed top-0 z-50 flex items-center justify-center">
        <div className="w-32 h-1 bg-white/20 rounded-full absolute bottom-2" />
      </div>

      {/* Main Content */}
      <main className="flex-1 flex flex-col pt-12 pb-24 overflow-y-auto px-6">
        {mode === 'timer' ? (
          <div className="flex-1 flex flex-col items-center justify-center gap-12 animate-in fade-in duration-500">
            {isFinished ? (
              <div className="text-center space-y-6">
                <div className="w-24 h-24 bg-[#34C759] rounded-full flex items-center justify-center mx-auto shadow-[0_0_40px_rgba(52,199,89,0.3)]">
                  <Play className="text-black fill-current" size={40} />
                </div>
                <h1 className="text-4xl font-black tracking-tight">ТРЕНИРОВКА ЗАВЕРШЕНА</h1>
                <button 
                  onClick={resetTimer}
                  className="px-8 py-4 bg-white text-black rounded-2xl font-bold active:scale-95 transition-transform"
                >
                  ПОВТОРИТЬ
                </button>
              </div>
            ) : (
              <>
                <div className="text-center space-y-2">
                  <div className={`inline-flex items-center gap-2 px-3 py-1 rounded-full ${getStageBg(currentStage?.type)} ${getStageColor(currentStage?.type)} text-[10px] font-black uppercase tracking-widest`}>
                    {currentStage?.type === 'run' && <Flame size={12} />}
                    {currentStage?.type === 'walk' && <Wind size={12} />}
                    {currentStage?.name}
                  </div>
                  <h2 className="text-xl font-medium text-[#8E8E93]">СЛЕДУЮЩИЙ: {stages[currentStageIndex + 1]?.name || 'ФИНИШ'}</h2>
                </div>

                <div className="text-[120px] font-black tracking-tighter tabular-nums leading-none">
                  {formatTime(timeLeft)}
                </div>

                <div className="flex flex-col items-center gap-2">
                  <div className="flex items-center gap-3 text-2xl font-bold text-[#8E8E93]">
                    <Move size={24} />
                    {currentStage?.speed} КМ/Ч
                  </div>
                  <div className="text-sm font-medium text-[#48484A]">ЭТАП {currentStageIndex + 1} ИЗ {stages.length}</div>
                </div>

                <div className="flex items-center gap-8">
                  <button 
                    onClick={skipPrev}
                    disabled={currentStageIndex === 0}
                    className="w-16 h-16 rounded-full bg-[#1C1C1E] flex items-center justify-center active:scale-90 transition-transform disabled:opacity-30"
                  >
                    <ChevronLeft size={32} />
                  </button>

                  <button 
                    onClick={toggleTimer}
                    className={`w-24 h-24 rounded-full flex items-center justify-center active:scale-95 transition-transform shadow-2xl ${
                      isActive ? 'bg-white text-black' : 'bg-[#0A84FF] text-white'
                    }`}
                  >
                    {isActive ? <Pause size={48} fill="currentColor" /> : <Play size={48} fill="currentColor" className="ml-2" />}
                  </button>

                  <button 
                    onClick={skipNext}
                    disabled={currentStageIndex === stages.length - 1}
                    className="w-16 h-16 rounded-full bg-[#1C1C1E] flex items-center justify-center active:scale-90 transition-transform disabled:opacity-30"
                  >
                    <ChevronRight size={32} />
                  </button>
                </div>

                <button 
                  onClick={resetTimer}
                  className="p-4 text-[#8E8E93] active:rotate-180 transition-transform duration-500"
                >
                  <RotateCcw size={24} />
                </button>
              </>
            )}
          </div>
        ) : (
          <div className="space-y-8 animate-in slide-in-from-bottom-4 duration-500">
            <div className="flex items-center justify-between pt-4">
              <h1 className="text-3xl font-black tracking-tight">ПЛАН ТРЕНИРОВКИ</h1>
              <div className="flex gap-2">
                <button onClick={() => addStage('run')} className="p-2 bg-[#FF3B30]/20 text-[#FF3B30] rounded-lg"><Plus size={20} /></button>
                <button onClick={() => addStage('walk')} className="p-2 bg-[#007AFF]/20 text-[#007AFF] rounded-lg"><Plus size={20} /></button>
              </div>
            </div>

            <div className="space-y-3">
              {stages.map((stage, index) => (
                <div key={stage.id} className="bg-[#1C1C1E] rounded-2xl p-4 flex items-center gap-4 group active:bg-[#2C2C2E] transition-colors">
                  <div className={`w-1.5 h-10 rounded-full ${stage.type === 'run' ? 'bg-[#FF3B30]' : 'bg-[#007AFF]'}`} />
                  
                  <div className="flex-1 space-y-1">
                    <input 
                      value={stage.name}
                      onChange={(e) => updateStage(stage.id, { name: e.target.value })}
                      className="bg-transparent font-bold block w-full outline-none"
                    />
                    <div className="flex gap-4 text-xs font-medium text-[#8E8E93]">
                      <div className="flex items-center gap-1">
                        <TimerIcon size={12} />
                        <input 
                          type="number"
                          value={stage.duration / 60}
                          onChange={(e) => updateStage(stage.id, { duration: Number(e.target.value) * 60 })}
                          className="bg-transparent w-8 text-white outline-none"
                        /> МИН
                      </div>
                      <div className="flex items-center gap-1">
                        <Move size={12} />
                        <input 
                          value={stage.speed}
                          onChange={(e) => updateStage(stage.id, { speed: e.target.value })}
                          className="bg-transparent w-8 text-white outline-none"
                        /> КМ/Ч
                      </div>
                    </div>
                  </div>

                  <div className="flex flex-col gap-1">
                    <button onClick={() => moveStage(index, 'up')} className="p-1 text-[#48484A] hover:text-white"><ChevronLeft size={16} className="rotate-90" /></button>
                    <button onClick={() => moveStage(index, 'down')} className="p-1 text-[#48484A] hover:text-white"><ChevronLeft size={16} className="-rotate-90" /></button>
                  </div>

                  <button 
                    onClick={() => removeStage(stage.id)}
                    className="p-3 text-[#FF3B30] opacity-0 group-hover:opacity-100 transition-opacity"
                  >
                    <Trash2 size={20} />
                  </button>
                </div>
              ))}
            </div>

            <div className="grid grid-cols-2 gap-3 pt-4">
              <button onClick={() => addStage('warmup')} className="p-4 bg-[#FFCC00]/10 text-[#FFCC00] rounded-2xl font-bold text-sm">РАЗМИНКА</button>
              <button onClick={() => addStage('cooldown')} className="p-4 bg-[#34C759]/10 text-[#34C759] rounded-2xl font-bold text-sm">ЗАМИНКА</button>
            </div>
          </div>
        )}
      </main>

      {/* iOS Tab Bar */}
      <nav className="h-20 w-full bg-[#121212]/80 backdrop-blur-2xl border-t border-white/5 fixed bottom-0 z-50 px-8 flex items-center justify-around pb-4">
        <button 
          onClick={() => setMode('builder')}
          className={`flex flex-col items-center gap-1 transition-colors ${mode === 'builder' ? 'text-[#0A84FF]' : 'text-[#8E8E93]'}`}
        >
          <LayoutGrid size={24} />
          <span className="text-[10px] font-medium uppercase tracking-wider">План</span>
        </button>

        <button 
          onClick={() => setMode('timer')}
          className={`flex flex-col items-center gap-1 transition-colors ${mode === 'timer' ? 'text-[#0A84FF]' : 'text-[#8E8E93]'}`}
        >
          <TimerIcon size={24} />
          <span className="text-[10px] font-medium uppercase tracking-wider">Таймер</span>
        </button>

        <button className="flex flex-col items-center gap-1 text-[#48484A]">
          <Settings size={24} />
          <span className="text-[10px] font-medium uppercase tracking-wider">Настройки</span>
        </button>
      </nav>
    </div>
  );
}

export default App;
