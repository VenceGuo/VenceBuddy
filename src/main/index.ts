/**
 * Electron 主进程入口
 */

import { app, BrowserWindow, ipcMain } from 'electron';
import path from 'path';
import { Gateway } from './gateway/router';
import { DeepSeekClient, defaultConfig as deepseekConfig } from './models/deepseek';
import { SiliconFlowVideoClient, defaultConfig as videoConfig } from './models/siliconflow-video';
import { skill as videoGenSkill } from './skills/video-gen';

let mainWindow: BrowserWindow | null = null;
let gateway: Gateway;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1000,
    minHeight: 700,
    webPreferences: {
      preload: path.join(__dirname, '../preload/index.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
    titleBarStyle: 'hiddenInset',
    backgroundColor: '#1a1a2e',
  });

  if (process.env['ELECTRON_RENDERER_URL']) {
    mainWindow.loadURL(process.env['ELECTRON_RENDERER_URL']);
  } else {
    mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));
  }
}

function initGateway() {
  const llm = new DeepSeekClient({
    ...deepseekConfig,
    apiKey: process.env.SILICONFLOW_API_KEY || process.env.DEEPSEEK_API_KEY || deepseekConfig.apiKey,
    baseUrl: process.env.DEEPSEEK_API_BASE || deepseekConfig.baseUrl,
    model: process.env.DEEPSEEK_MODEL || deepseekConfig.model,
  });

  gateway = new Gateway(llm);

  const videoClient = new SiliconFlowVideoClient({
    ...videoConfig,
    apiKey: process.env.SILICONFLOW_API_KEY || process.env.DEEPSEEK_API_KEY || videoConfig.apiKey,
  });

  gateway.registerTool(
    'generate_video',
    { type: 'function', function: videoGenSkill },
    async (args) => {
      const result = await videoClient.generateAndWait(
        {
          prompt: args.prompt as string,
          image: args.image as string | undefined,
          imageSize: args.image_size as '1280x720' | '720x1280' | '960x960' | undefined,
          negativePrompt: args.negative_prompt as string | undefined,
          seed: args.seed as number | undefined,
        },
        (status, taskResult) => {
          if (mainWindow) {
            mainWindow.webContents.send('video:progress', {
              requestId: taskResult?.requestId,
              status,
            });
          }
        }
      );

      return result.videoUrl
        ? { url: result.videoUrl, seed: result.seed, inferenceTime: result.inferenceTime }
        : { url: null, message: 'No video generated' };
    }
  );
}

function initIPC() {
  ipcMain.handle('task:submit', async (_event, prompt: string) => {
    const task = await gateway.processMessage(prompt, 'default');
    return task;
  });

  ipcMain.handle('task:list', () => {
    return gateway.getAllTasks();
  });

  ipcMain.handle('task:get', (_event, taskId: string) => {
    return gateway.getTask(taskId);
  });
}

app.whenReady().then(() => {
  initGateway();
  initIPC();
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
