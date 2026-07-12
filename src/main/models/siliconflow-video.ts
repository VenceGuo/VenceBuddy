/**
 * SiliconFlow 视频生成适配器
 * 基于硅基流动 Wan2.2 系列模型，支持文生视频和图生视频
 * 异步 API：提交任务 (POST /video/submit) + 轮询结果 (POST /video/status)
 * 文档：https://docs.siliconflow.cn/api-reference/videos
 */

export interface VideoConfig {
  baseUrl: string;
  apiKey: string;
  defaultModel: string;
  defaultImageSize: string;
  pollInterval: number;
}

export interface VideoGenerateRequest {
  prompt: string;
  model?: string;
  image?: string;
  imageSize?: '1280x720' | '720x1280' | '960x960';
  negativePrompt?: string;
  seed?: number;
}

export type VideoStatus = 'InQueue' | 'InProgress' | 'Succeed' | 'Failed';

export interface VideoTaskResult {
  requestId: string;
  status: VideoStatus;
  reason?: string;
  videoUrl?: string;
  seed?: number;
  inferenceTime?: number;
}

export class SiliconFlowVideoClient {
  private config: VideoConfig;

  constructor(config: VideoConfig) {
    this.config = config;
  }

  /**
   * 提交视频生成任务
   * 返回 requestId 用于后续轮询
   */
  async submitVideo(request: VideoGenerateRequest): Promise<string> {
    const model = request.model || this.config.defaultModel;
    const isImageToVideo = !!request.image;

    // 根据是否有图片自动选择模型
    const finalModel = isImageToVideo && !request.model
      ? 'Wan-AI/Wan2.2-I2V-A14B'
      : model;

    const body: Record<string, unknown> = {
      model: finalModel,
      prompt: request.prompt,
      image_size: request.imageSize || this.config.defaultImageSize,
    };

    if (request.image) {
      body.image = request.image;
    }

    if (request.negativePrompt) {
      body.negative_prompt = request.negativePrompt;
    }

    if (request.seed !== undefined) {
      body.seed = request.seed;
    }

    const response = await fetch(`${this.config.baseUrl}/video/submit`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.config.apiKey}`,
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`SiliconFlow video submit error (${response.status}): ${errorText}`);
    }

    const data = await response.json();
    return data.requestId;
  }

  /**
   * 查询视频生成状态
   */
  async queryStatus(requestId: string): Promise<VideoTaskResult> {
    const response = await fetch(`${this.config.baseUrl}/video/status`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.config.apiKey}`,
      },
      body: JSON.stringify({ requestId }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`SiliconFlow video status error (${response.status}): ${errorText}`);
    }

    const data = await response.json();

    return {
      requestId,
      status: data.status as VideoStatus,
      reason: data.reason || undefined,
      videoUrl: data.results?.videos?.[0]?.url,
      seed: data.results?.seed,
      inferenceTime: data.results?.timings?.inference,
    };
  }

  /**
   * 提交并等待视频生成完成
   * 通过回调报告进度
   */
  async generateAndWait(
    request: VideoGenerateRequest,
    onProgress?: (status: VideoStatus, result?: VideoTaskResult) => void,
    timeoutMs: number = 600000
  ): Promise<VideoTaskResult> {
    const requestId = await this.submitVideo(request);
    console.log(`[Video] Submitted, requestId: ${requestId}`);

    const startTime = Date.now();

    while (Date.now() - startTime < timeoutMs) {
      const result = await this.queryStatus(requestId);

      if (onProgress) {
        onProgress(result.status, result);
      }

      if (result.status === 'Succeed') {
        return result;
      }

      if (result.status === 'Failed') {
        throw new Error(`Video generation failed: ${result.reason || 'unknown error'}`);
      }

      // InQueue or InProgress — 继续轮询
      await new Promise((resolve) => setTimeout(resolve, this.config.pollInterval));
    }

    throw new Error(`Video generation timed out after ${timeoutMs / 1000}s`);
  }

  getAvailableModels() {
    return [
      {
        id: 'Wan-AI/Wan2.2-T2V-A14B',
        type: 'text-to-video',
        description: 'Wan2.2 文生视频，MoE 架构，支持 1280x720 / 720x1280 / 960x960',
        price: '~2 元/视频',
      },
      {
        id: 'Wan-AI/Wan2.2-I2V-A14B',
        type: 'image-to-video',
        description: 'Wan2.2 图生视频，基于参考图片生成视频',
        price: '~2 元/视频',
      },
    ];
  }
}

export const defaultConfig: VideoConfig = {
  baseUrl: process.env.SILICONFLOW_API_BASE || 'https://api.siliconflow.cn/v1',
  apiKey: process.env.SILICONFLOW_API_KEY || process.env.DEEPSEEK_API_KEY || '',
  defaultModel: 'Wan-AI/Wan2.2-T2V-A14B',
  defaultImageSize: '1280x720',
  pollInterval: 5000,
};
