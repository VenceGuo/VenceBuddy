import React from 'react';

interface ChatPanelProps {
  messages: { role: string; content: string }[];
  onSubmit: (prompt: string) => void;
}

export function ChatPanel({ messages, onSubmit }: ChatPanelProps) {
  const [input, setInput] = React.useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (input.trim()) {
      onSubmit(input);
      setInput('');
    }
  };

  return (
    <div className="flex flex-col h-full">
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((msg, i) => (
          <div key={i} className={msg.role === 'user' ? 'text-right' : 'text-left'}>
            <div className={`inline-block max-w-[80%] px-4 py-2 rounded-lg ${
              msg.role === 'user' ? 'bg-blue-600' : 'bg-gray-800'
            }`}>
              {msg.content}
            </div>
          </div>
        ))}
      </div>
      <form onSubmit={handleSubmit} className="p-4 border-t border-gray-800 flex gap-2">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="输入任务..."
          className="flex-1 bg-gray-800 text-gray-100 px-4 py-2 rounded-lg outline-none"
        />
        <button type="submit" className="px-6 py-2 bg-blue-600 rounded-lg hover:bg-blue-500">
          Send
        </button>
      </form>
    </div>
  );
}
