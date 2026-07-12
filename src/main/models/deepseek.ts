/**
 * DeepSeek V3.2 模型适配器
 * OpenAI 兼容 API，支持 Function Calling 和 JSON Mode
 */

export interface DeepSeekConfig {
  baseUrl: string;
  apiKey: string;
  model: string;
  contextWindow: number;
  toolCalling: boolean;
}

export interface ChatMessage {
  role: 'system' | 'user' | 'assistant' | 'tool';
  content: string;
  tool_calls?: ToolCall[];
  tool_call_id?: string;
}

export interface ToolCall {
  id: string;
  type: 'function';
  function: {
    name: string;
    arguments: string;
  };
}

export interface ToolDefinition {
  type: 'function';
  function: {
    name: string;
    description: string;
    parameters: Record<string, unknown>;
  };
}

export class DeepSeekClient {
  private config: DeepSeekConfig;

  constructor(config: DeepSeekConfig) {
    this.config = config;
  }

  async chat(
    messages: ChatMessage[],
    tools?: ToolDefinition[],
    options?: {
      temperature?: number;
      maxTokens?: number;
      jsonMode?: boolean;
      stream?: boolean;
    }
  ): Promise<ChatMessage> {
    const body: Record<string, unknown> = {
      model: this.config.model,
      messages,
      temperature: options?.temperature ?? 0.7,
      max_tokens: options?.maxTokens ?? 8192,
    };

    if (tools && tools.length > 0 && this.config.toolCalling) {
      body.tools = tools;
      body.tool_choice = 'auto';
    }

    if (options?.jsonMode) {
      body.response_format = { type: 'json_object' };
    }

    if (options?.stream) {
      body.stream = true;
    }

    const response = await fetch(`${this.config.baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.config.apiKey}`,
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      throw new Error(`DeepSeek API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    return data.choices[0].message;
  }

  async chatStream(
    messages: ChatMessage[],
    tools?: ToolDefinition[]
  ): AsyncGenerator<string> {
    const body: Record<string, unknown> = {
      model: this.config.model,
      messages,
      stream: true,
    };

    if (tools && tools.length > 0 && this.config.toolCalling) {
      body.tools = tools;
      body.tool_choice = 'auto';
    }

    const response = await fetch(`${this.config.baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.config.apiKey}`,
      },
      body: JSON.stringify(body),
    });

    const reader = response.body!.getReader();
    const decoder = new TextDecoder();

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = decoder.decode(value);
      const lines = chunk.split('\n').filter((l) => l.startsWith('data: '));

      for (const line of lines) {
        const data = line.slice(6);
        if (data === '[DONE]') return;

        try {
          const parsed = JSON.parse(data);
          const delta = parsed.choices[0]?.delta?.content;
          if (delta) yield delta;
        } catch {
          // skip invalid JSON
        }
      }
    }
  }
}

export const defaultConfig: DeepSeekConfig = {
  baseUrl: process.env.DEEPSEEK_API_BASE || 'https://api.siliconflow.cn/v1',
  apiKey: process.env.SILICONFLOW_API_KEY || process.env.DEEPSEEK_API_KEY || '',
  model: process.env.DEEPSEEK_MODEL || 'deepseek-ai/DeepSeek-V4-Pro',
  contextWindow: 128000,
  toolCalling: true,
};
