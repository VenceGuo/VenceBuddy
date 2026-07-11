/**
 * Electron 主进程入口
 */

import { app, BrowserWindow, ipcMain } from 'electron';
import path from 'path';
import { Gateway } from './gateway/router';
import { DeepSeekClient, defaultConfig as deepseekConfig } from './models/deepseek';
import { SeedDanceClient, defaultConfig as seeddanceConfig } from './models/seeddance';
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
    apiKey: process.env.DEEPSEEK_API_KEY || deepseekConfig.apiKey,
  });

  gateway = new Gateway(llm);

  const seeddance = new SeedDanceClient({
    ...seeddanceConfig,
    apiKey: process.env.SEEDDANCE_API_KEY || seeddanceConfig.apiKey,
  });

  gateway.registerTool(
    'generate_video',
    { type: 'function', function: videoGenSkill },
    async (args) => {
      const taskId = await seeddance.generateVideo({
        prompt: args.prompt as string,
        image: args.image as string | undefined,
        model: args.model as string | undefined,
      });

      const result = await seeddance.waitForCompletion(taskId, (status) => {
        if (mainWindow) {
          mainWindow.webContents.send('video:progress', { taskId, status });
        }
      });

      return result.videos?.[0] || { url: null, message: 'No video generated' };
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
