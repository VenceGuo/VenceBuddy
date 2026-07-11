/**
 * SeedDance 视频生成 Skill
 * OpenClaw Skill 格式，封装为工具供 LLM 调用
 */

import { SeedDanceClient } from '../models/seeddance';

const skill = {
  name: 'generate_video',
  description: 'Generate a video from a text prompt or an image. Supports text-to-video and image-to-video modes.',
  parameters: {
    type: 'object',
    properties: {
      prompt: {
        type: 'string',
        description: 'Text description of the video to generate',
      },
      image: {
        type: 'string',
        description: 'URL of a reference image for image-to-video mode (optional)',
      },
      model: {
        type: 'string',
        description: 'Model to use: seedance-pro-5s, seedance-pro-10s, seedance-lite-5s, etc.',
      },
    },
    required: ['prompt'],
  },
};

export { skill };
