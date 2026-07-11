import React from 'react';

interface ResultPanelProps {
  task: any;
}

export function ResultPanel({ task }: ResultPanelProps) {
  if (!task) {
    return (
      <div className="flex items-center justify-center h-full text-gray-600 text-sm">
        Select a task to view results
      </div>
    );
  }

  return (
    <div className="p-4 overflow-y-auto h-full">
      <h3 className="text-sm font-medium text-gray-400 mb-3">Result</h3>
      <div className="text-sm text-gray-300 mb-4">{task.prompt}</div>

      {task.result && typeof task.result === 'string' && (
        <div className="bg-gray-800/50 p-3 rounded-lg text-sm">
          {task.result}
        </div>
      )}

      {task.result && typeof task.result === 'object' && (task.result as any).url && (
        <div className="mt-4">
          <video
            src={(task.result as any).url}
            controls
            className="w-full rounded-lg"
          />
        </div>
      )}
    </div>
  );
}
