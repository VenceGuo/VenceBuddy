/**
 * 主应用组件 - 三栏布局（任务列表 + 对话 + 结果预览）
 */

import React, { useState, useEffect } from 'react';
import { ChatPanel } from './components/ChatPanel';
import { TaskPanel } from './components/TaskPanel';
import { ResultPanel } from './components/ResultPanel';

const { api } = window as any;

export default function App() {
  const [tasks, setTasks] = useState<any[]>([]);
  const [activeTask, setActiveTask] = useState<any>(null);
  const [messages, setMessages] = useState<{role: string; content: string}[]>([]);

  useEffect(() => {
    loadTasks();
  }, []);

  const loadTasks = async () => {
    const list = await api.task.list();
    setTasks(list);
  };

  const handleSubmit = async (prompt: string) => {
    setMessages(prev => [...prev, { role: 'user', content: prompt }]);
    setMessages(prev => [...prev, { role: 'assistant', content: 'Processing...' }]);

    const task = await api.task.submit(prompt);
    setActiveTask(task);
    setMessages(prev => [
      ...prev.slice(0, -1),
      { role: 'assistant', content: task.result || 'Task completed' }
    ]);
    await loadTasks();
  };

  return (
    <div className="flex h-screen bg-[#1a1a2e] text-gray-100">
      {/* 左栏：任务列表 */}
      <div className="w-64 border-r border-gray-800 flex flex-col">
        <TaskPanel tasks={tasks} activeTask={activeTask} onSelect={setActiveTask} />
      </div>

      {/* 中栏：对话 */}
      <div className="flex-1 flex flex-col">
        <ChatPanel messages={messages} onSubmit={handleSubmit} />
      </div>

      {/* 右栏：结果预览 */}
      <div className="w-96 border-l border-gray-800">
        <ResultPanel task={activeTask} />
      </div>
    </div>
  );
}
