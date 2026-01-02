import React, { useState, useEffect } from 'react';
import { Clock, Plus, Play, Pause, CheckCircle, Circle, Trash2, Timer, Target, Zap, Brain } from 'lucide-react';

const EngineerTimeManager = () => {
  const [tasks, setTasks] = useState([]);
  const [interruptions, setInterruptions] = useState([]);
  const [activeTimer, setActiveTimer] = useState(null);
  const [timeElapsed, setTimeElapsed] = useState(0);
  const [newTask, setNewTask] = useState('');
  const [newInterruption, setNewInterruption] = useState('');
  const [focusMode, setFocusMode] = useState(false);
  const [completedToday, setCompletedToday] = useState(0);

  // Timer effect
  useEffect(() => {
    let interval = null;
    if (activeTimer) {
      interval = setInterval(() => {
        setTimeElapsed(time => time + 1);
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [activeTimer]);

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const addTask = () => {
    if (newTask.trim()) {
      setTasks([...tasks, {
        id: Date.now(),
        text: newTask,
        completed: false,
        timeSpent: 0,
        priority: 'medium'
      }]);
      setNewTask('');
    }
  };

  const toggleTask = (id) => {
    setTasks(tasks.map(task => {
      if (task.id === id) {
        const updated = { ...task, completed: !task.completed };
        if (updated.completed && !task.completed) {
          setCompletedToday(prev => prev + 1);
        } else if (!updated.completed && task.completed) {
          setCompletedToday(prev => Math.max(0, prev - 1));
        }
        return updated;
      }
      return task;
    }));
  };

  const deleteTask = (id) => {
    const task = tasks.find(t => t.id === id);
    if (task && task.completed) {
      setCompletedToday(prev => Math.max(0, prev - 1));
    }
    setTasks(tasks.filter(task => task.id !== id));
  };

  const startTimer = (taskId) => {
    if (activeTimer === taskId) {
      setActiveTimer(null);
    } else {
      setActiveTimer(taskId);
      setTimeElapsed(0);
    }
  };

  const logInterruption = () => {
    if (newInterruption.trim()) {
      setInterruptions([...interruptions, {
        id: Date.now(),
        text: newInterruption,
        time: new Date().toLocaleTimeString()
      }]);
      setNewInterruption('');
    }
  };

  const clearInterruptions = () => {
    setInterruptions([]);
  };

  const pendingTasks = tasks.filter(task => !task.completed);
  const completedTasks = tasks.filter(task => task.completed);

  return (
    <div className="max-w-6xl mx-auto p-6 bg-gray-50 min-h-screen">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-800 mb-2">Engineering Command Center</h1>
        <p className="text-gray-600">Manage everything from one place. No more drowning in endless piles.</p>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <div className="bg-blue-100 p-4 rounded-lg">
          <div className="flex items-center">
            <Target className="text-blue-600 mr-2" size={24} />
            <div>
              <div className="text-2xl font-bold text-blue-800">{pendingTasks.length}</div>
              <div className="text-blue-600 text-sm">Pending Tasks</div>
            </div>
          </div>
        </div>
        <div className="bg-green-100 p-4 rounded-lg">
          <div className="flex items-center">
            <CheckCircle className="text-green-600 mr-2" size={24} />
            <div>
              <div className="text-2xl font-bold text-green-800">{completedToday}</div>
              <div className="text-green-600 text-sm">Completed Today</div>
            </div>
          </div>
        </div>
        <div className="bg-orange-100 p-4 rounded-lg">
          <div className="flex items-center">
            <Zap className="text-orange-600 mr-2" size={24} />
            <div>
              <div className="text-2xl font-bold text-orange-800">{interruptions.length}</div>
              <div className="text-orange-600 text-sm">Interruptions</div>
            </div>
          </div>
        </div>
        <div className="bg-purple-100 p-4 rounded-lg">
          <div className="flex items-center">
            <Brain className="text-purple-600 mr-2" size={24} />
            <div>
              <div className="text-2xl font-bold text-purple-800">
                {focusMode ? 'ON' : 'OFF'}
              </div>
              <div className="text-purple-600 text-sm">Focus Mode</div>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Task Panel */}
        <div className="lg:col-span-2 space-y-6">
          {/* Add Task */}
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <h2 className="text-xl font-semibold mb-4">Add New Task</h2>
            <div className="flex gap-2">
              <input
                type="text"
                value={newTask}
                onChange={(e) => setNewTask(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && addTask()}
                placeholder="What needs to be done?"
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <button
                onClick={addTask}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 flex items-center gap-2"
              >
                <Plus size={20} /> Add
              </button>
            </div>
          </div>

          {/* Active Tasks */}
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <h2 className="text-xl font-semibold mb-4">Current Tasks ({pendingTasks.length})</h2>
            <div className="space-y-3">
              {pendingTasks.map(task => (
                <div key={task.id} className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
                  <button
                    onClick={() => toggleTask(task.id)}
                    className="text-gray-400 hover:text-green-600"
                  >
                    <Circle size={20} />
                  </button>
                  <span className="flex-1">{task.text}</span>
                  <div className="flex items-center gap-2">
                    {activeTimer === task.id && (
                      <span className="text-blue-600 font-mono">{formatTime(timeElapsed)}</span>
                    )}
                    <button
                      onClick={() => startTimer(task.id)}
                      className={`p-2 rounded ${activeTimer === task.id ? 'bg-red-100 text-red-600' : 'bg-blue-100 text-blue-600'} hover:opacity-80`}
                    >
                      {activeTimer === task.id ? <Pause size={16} /> : <Play size={16} />}
                    </button>
                    <button
                      onClick={() => deleteTask(task.id)}
                      className="p-2 text-gray-400 hover:text-red-600"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                </div>
              ))}
              {pendingTasks.length === 0 && (
                <div className="text-center py-8 text-gray-500">
                  🎉 No pending tasks! Time to add some or take a break.
                </div>
              )}
            </div>
          </div>

          {/* Completed Tasks */}
          {completedTasks.length > 0 && (
            <div className="bg-white rounded-lg p-6 shadow-sm">
              <h2 className="text-xl font-semibold mb-4 text-green-700">Completed Today ({completedTasks.length})</h2>
              <div className="space-y-2">
                {completedTasks.slice(-5).map(task => (
                  <div key={task.id} className="flex items-center gap-3 p-2 text-gray-600">
                    <CheckCircle size={16} className="text-green-500" />
                    <span className="line-through">{task.text}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Focus Mode Toggle */}
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <h3 className="text-lg font-semibold mb-3">Focus Mode</h3>
            <button
              onClick={() => setFocusMode(!focusMode)}
              className={`w-full py-3 px-4 rounded-lg font-medium ${focusMode ? 'bg-purple-600 text-white' : 'bg-gray-200 text-gray-700'} hover:opacity-80`}
            >
              {focusMode ? 'Focus Mode ON' : 'Activate Focus Mode'}
            </button>
            <p className="text-sm text-gray-600 mt-2">
              {focusMode ? 'Minimize distractions and stay in the zone!' : 'Block distractions and enter deep work mode'}
            </p>
          </div>

          {/* Interruption Logger */}
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <h3 className="text-lg font-semibold mb-3">Log Interruptions</h3>
            <div className="space-y-3">
              <input
                type="text"
                value={newInterruption}
                onChange={(e) => setNewInterruption(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && logInterruption()}
                placeholder="Quick note about interruption..."
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-orange-500 text-sm"
              />
              <button
                onClick={logInterruption}
                className="w-full py-2 bg-orange-600 text-white rounded-md hover:bg-orange-700 text-sm"
              >
                Log It
              </button>
            </div>
            
            {interruptions.length > 0 && (
              <div className="mt-4">
                <div className="flex justify-between items-center mb-2">
                  <span className="text-sm font-medium">Today's Interruptions</span>
                  <button
                    onClick={clearInterruptions}
                    className="text-xs text-gray-500 hover:text-red-600"
                  >
                    Clear
                  </button>
                </div>
                <div className="space-y-1 max-h-32 overflow-y-auto">
                  {interruptions.slice(-5).map(interruption => (
                    <div key={interruption.id} className="text-xs bg-gray-50 p-2 rounded">
                      <span className="text-gray-500">{interruption.time}</span>
                      <div>{interruption.text}</div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Quick Tips */}
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <h3 className="text-lg font-semibold mb-3">Engineer's Time Tips</h3>
            <div className="space-y-2 text-sm text-gray-600">
              <div>• Batch similar tasks together</div>
              <div>• Use the timer for focused work blocks</div>
              <div>• Log interruptions to see patterns</div>
              <div>• Celebrate completed tasks!</div>
              <div>• When overwhelmed, pick just ONE task</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EngineerTimeManager;