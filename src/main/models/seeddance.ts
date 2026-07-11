/**
 * SeedDance 2.0 视频生成适配器
 * 支持文生视频、图生视频，异步 API（提交任务 + 轮询结果）
 */

export interface SeedDanceConfig {
  baseUrl: string;
  apiKey: string;
  defaultModel: string;
  pollInterval: number;
}

export interface VideoGenerateRequest {
  prompt?: string;
  model?: string;
  image?: string;
  duration?: '5' | '10';
  resolution?: '480p' | '720p' | '1080p';
  audio?: boolean;
}

export interface VideoTask {
  taskId: string;
  status: 'pending' | 'processing' | 'success' | 'failed';
  model: string;
  scene: string;
  videos?: { url: string }[];
  error?: string;
}

export class SeedDanceClient {
  private config: SeedDanceConfig;

  constructor(config: SeedDanceConfig) {
    this.config = config;
  }

  async generateVideo(request: VideoGenerateRequest): Promise<string> {
    const body: Record<string, unknown> = {
      prompt: request.prompt,
      model: request.model || this.config.defaultModel,
    };

    if (request.image) {
      body.image = request.image;
    }

    const response = await fetch(`${this.config.baseUrl}/video/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.config.apiKey}`,
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      throw new Error(`SeedDance API error: ${response.status}`);
    }

    const data = await response.json();
    if (data.code !== 0) {
      throw new Error(data.message || 'Video generation failed');
    }

    return data.data.task_id;
  }

  async queryTask(taskId: string): Promise<VideoTask> {
    const response = await fetch(`${this.config.baseUrl}/video/query`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.config.apiKey}`,
      },
      body: JSON.stringify({ task_id: taskId }),
    });

    if (!response.ok) {
      throw new Error(`SeedDance query error: ${response.status}`);
    }

    const data = await response.json();
    if (data.code !== 0) {
      throw new Error(data.message || 'Query failed');
    }

    return {
      taskId: data.data.task_id,
      status: data.data.status,
      model: data.data.model,
      scene: data.data.scene,
      videos: data.data.videos,
    };
  }

  async waitForCompletion(
    taskId: string,
    onProgress?: (status: string) => void,
    timeoutMs: number = 300000
  ): Promise<VideoTask> {
    const startTime = Date.now();

    while (Date.now() - startTime < timeoutMs) {
      const task = await this.queryTask(taskId);

      if (onProgress) {
        onProgress(task.status);
      }

      if (task.status === 'success') {
        return task;
      }

      if (task.status === 'failed') {
        throw new Error(`Video generation failed: ${task.error || 'unknown'}`);
      }

      await new Promise((resolve) =>
        setTimeout(resolve, this.config.pollInterval)
      );
    }

    throw new Error('Video generation timed out');
  }

  getAvailableModels() {
    return [
      { id: 'seedance-lite-5s', resolution: '720p', duration: '5s', cost: 12 },
      { id: 'seedance-lite-10s', resolution: '720p', duration: '10s', cost: 24 },
      { id: 'seedance-pro-5s', resolution: '1080p', duration: '5s', cost: 35 },
      { id: 'seedance-pro-10s', resolution: '1080p', duration: '10s', cost: 70 },
      { id: 'seedance-1.5-pro-5s', resolution: '1080p+audio', duration: '5s', cost: 50 },
      { id: 'seedance-1.5-pro-10s', resolution: '1080p+audio', duration: '10s', cost: 100 },
    ];
  }
}

export const defaultConfig: SeedDanceConfig = {
  baseUrl: 'https://api.seedanceapi.dev/v1',
  apiKey: process.env.SEEDDANCE_API_KEY || '',
  defaultModel: 'seedance-pro-5s',
  pollInterval: 5000,
};
