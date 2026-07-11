/**
 * Electron Preload 脚本
 * 通过 contextBridge 暴露安全 API 给渲染进程
 */

import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('api', {
  task: {
    submit: (prompt: string) => ipcRenderer.invoke('task:submit', prompt),
    list: () => ipcRenderer.invoke('task:list'),
    get: (taskId: string) => ipcRenderer.invoke('task:get', taskId),
  },
  video: {
    onProgress: (callback: (data: { taskId: string; status: string }) => void) => {
      ipcRenderer.on('video:progress', (_event, data) => callback(data));
    },
  },
});
