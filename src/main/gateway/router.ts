/**
 * OpenClaw Gateway 核心路由
 * 负责消息路由、任务调度和工具执行
 */

import { DeepSeekClient, type ChatMessage, type ToolDefinition } from '../models/deepseek';

export interface Task {
  id: string;
  status: 'pending' | 'planning' | 'executing' | 'completed' | 'failed';
  prompt: string;
  steps: TaskStep[];
  result?: unknown;
  createdAt: number;
}

export interface TaskStep {
  id: string;
  description: string;
  toolName?: string;
  toolArgs?: Record<string, unknown>;
  status: 'pending' | 'in_progress' | 'completed' | 'failed';
  result?: unknown;
}

export class Gateway {
  private llm: DeepSeekClient;
  private tools: Map<string, ToolDefinition> = new Map();
  private tasks: Map<string, Task> = new Map();
  private handlers: Map<string, (args: Record<string, unknown>) => Promise<unknown>> = new Map();

  constructor(llm: DeepSeekClient) {
    this.llm = llm;
  }

  registerTool(
    name: string,
    definition: ToolDefinition,
    handler: (args: Record<string, unknown>) => Promise<unknown>
  ) {
    this.tools.set(name, definition);
    this.handlers.set(name, handler);
  }

  async processMessage(userInput: string, sessionId: string): Promise<Task> {
    const task: Task = {
      id: `task_${Date.now()}`,
      status: 'planning',
      prompt: userInput,
      steps: [],
      createdAt: Date.now(),
    };

    this.tasks.set(task.id, task);

    const systemPrompt = `You are an AI workbench assistant. Break down the user's request into actionable steps.
You have access to tools. Use them when needed.
Always respond in the user's language.

Available tools: ${Array.from(this.tools.keys()).join(', ')}`;

    const messages: ChatMessage[] = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userInput },
    ];

    const toolList = Array.from(this.tools.values());
    task.status = 'executing';

    let maxRounds = 10;
    while (maxRounds-- > 0) {
      const response = await this.llm.chat(messages, toolList);

      if (response.tool_calls && response.tool_calls.length > 0) {
        messages.push(response);

        for (const call of response.tool_calls) {
          const handler = this.handlers.get(call.function.name);
          if (!handler) {
            messages.push({
              role: 'tool',
              tool_call_id: call.id,
              content: `Error: tool ${call.function.name} not found`,
            });
            continue;
          }

          const args = JSON.parse(call.function.arguments);
          try {
            const result = await handler(args);
            messages.push({
              role: 'tool',
              tool_call_id: call.id,
              content: JSON.stringify(result),
            });
          } catch (err) {
            messages.push({
              role: 'tool',
              tool_call_id: call.id,
              content: `Error: ${(err as Error).message}`,
            });
          }
        }
      } else {
        task.status = 'completed';
        task.result = response.content;
        break;
      }
    }

    if (maxRounds <= 0) {
      task.status = 'failed';
      task.result = 'Max tool-calling rounds exceeded';
    }

    return task;
  }

  getTask(taskId: string): Task | undefined {
    return this.tasks.get(taskId);
  }

  getAllTasks(): Task[] {
    return Array.from(this.tasks.values());
  }
}
