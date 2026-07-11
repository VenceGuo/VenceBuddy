import React from 'react';

interface Task {
  id: string;
  status: string;
  prompt: string;
  createdAt: number;
}

interface TaskPanelProps {
  tasks: Task[];
  activeTask: Task | null;
  onSelect: (task: Task) => void;
}

export function TaskPanel({ tasks, activeTask, onSelect }: TaskPanelProps) {
  return (
    <div className="flex flex-col h-full">
      <div className="p-4 border-b border-gray-800">
        <h2 className="text-sm font-medium text-gray-400">Tasks</h2>
      </div>
      <div className="flex-1 overflow-y-auto">
        {tasks.length === 0 ? (
          <div className="p-4 text-center text-gray-600 text-sm">No tasks yet</div>
        ) : (
          tasks.map((task) => (
            <button
              key={task.id}
              onClick={() => onSelect(task)}
              className={`w-full text-left p-3 border-b border-gray-800 hover:bg-gray-800/50 ${
                activeTask?.id === task.id ? 'bg-gray-800' : ''
              }`}
            >
              <div className="text-xs text-gray-500 mb-1">{task.id}</div>
              <div className="text-sm truncate">{task.prompt}</div>
              <div className={`text-xs mt-1 ${
                task.status === 'completed' ? 'text-green-500' :
                task.status === 'failed' ? 'text-red-500' :
                'text-yellow-500'
              }`}>
                {task.status}
              </div>
            </button>
          ))
        )}
      </div>
    </div>
  );
}
