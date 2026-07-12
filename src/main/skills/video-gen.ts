/**
 * 视频生成 Skill
 * 使用硅基流动 Wan2.2 系列模型，支持文生视频和图生视频
 */

import { SiliconFlowVideoClient } from '../models/siliconflow-video';

const skill = {
  name: 'generate_video',
  description: 'Generate a video from a text prompt or an image using SiliconFlow Wan2.2 models. Supports text-to-video (T2V) and image-to-video (I2V).',
  parameters: {
    type: 'object',
    properties: {
      prompt: {
        type: 'string',
        description: 'Text description of the video to generate. Be descriptive about scenes, camera movements, and visual style.',
      },
      image: {
        type: 'string',
        description: 'URL or base64 of a reference image for image-to-video mode. If provided, the I2V model will be used automatically.',
      },
      image_size: {
        type: 'string',
        enum: ['1280x720', '720x1280', '960x960'],
        description: 'Output video resolution. 1280x720 = landscape, 720x1280 = portrait, 960x960 = square. Default: 1280x720',
      },
      negative_prompt: {
        type: 'string',
        description: 'Negative prompt - things to avoid in the generated video (optional)',
      },
      seed: {
        type: 'number',
        description: 'Random seed for reproducible results (optional)',
      },
    },
    required: ['prompt'],
  },
};

export { skill };
