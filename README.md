# VenceBuddy

> 基于 OpenClaw 架构的全场景 AI 办公工作台，使用 DeepSeek V3.2 作为 LLM，SeedDance 2.0 作为视频生成模型。

## 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| 前端 | Electron + React + TypeScript | 桌面应用框架 |
| UI | TailwindCSS + Lucide Icons | 样式与图标 |
| 网关 | Node.js + WebSocket | OpenClaw Gateway 架构 |
| LLM | DeepSeek V3.2 | 128K 上下文，Agent 优化，Function Calling |
| 视频生成 | SeedDance 2.0 | 文生视频 / 图生视频 / 原生音频 |
| 存储 | SQLite (better-sqlite3) | 本地任务记录与记忆系统 |
| 状态管理 | Zustand | 轻量级前端状态 |

## 项目结构

```
VenceBuddy/
├── src/
│   ├── main/              # Electron 主进程
│   │   ├── index.ts       # 入口
│   │   ├── gateway/       # OpenClaw Gateway 核心逻辑
│   │   │   ├── router.ts       # 消息路由
│   │   │   ├── context.ts      # 上下文管理
│   │   │   ├── executor.ts     # 工具调度
│   │   │   └── sandbox.ts      # 安全沙箱
│   │   ├── models/        # 模型适配层
│   │   │   ├── deepseek.ts     # DeepSeek V3.2 适配
│   │   │   └── seeddance.ts    # SeedDance 2.0 适配
│   │   └── ipc/           # IPC 通信
│   ├── renderer/          # Electron 渲染进程 (React)
│   │   ├── App.tsx
│   │   ├── components/     # UI 组件
│   │   │   ├── ChatPanel/      # 对话面板
│   │   │   ├── TaskPanel/      # 任务管理面板
│   │   │   ├── FileViewer/     # 文件预览
│   │   │   └── VideoPlayer/    # 视频播放
│   │   ├── stores/        # Zustand 状态
│   │   ├── hooks/         # React Hooks
│   │   └── styles/        # 全局样式
│   ├── preload/           # Electron preload 脚本
│   └── shared/            # 主进程/渲染进程共享类型
├── skills/                # OpenClaw Skills
│   ├── fs-operations/     # 文件操作技能
│   ├── browser-automation/# 浏览器自动化
│   ├── doc-processing/    # 文档处理
│   └── video-gen/         # SeedDance 视频生成
├── config/                # 配置文件
│   ├── deepseek.json      # DeepSeek 模型配置
│   ├── seeddance.json     # SeedDance API 配置
│   └── skills.json        # 技能注册表
├── electron-builder.yml   # 打包配置
├── electron.vite.config.ts # Vite 配置
├── tsconfig.json
├── tailwind.config.js
└── package.json
```

## 快速开始

```bash
# 安装依赖
npm install

# 开发模式启动
npm run dev

# 打包
npm run package:win
```

## 配置

### DeepSeek API

在 `config/deepseek.json` 中配置（或使用环境变量）：

```json
{
  "baseUrl": "https://api.deepseek.com/v1",
  "apiKey": "${DEEPSEEK_API_KEY}",
  "model": "deepseek-chat",
  "contextWindow": 128000,
  "toolCalling": true
}
```

### SeedDance API

在 `config/seeddance.json` 中配置：

```json
{
  "baseUrl": "https://api.seedanceapi.dev/v1",
  "apiKey": "${SEEDDANCE_API_KEY}",
  "defaultModel": "seedance-pro-5s",
  "pollInterval": 5000
}
```

## 远程仓库

- **Gitee (主)**: https://gitee.com/VenceGuo/VenceBuddy
- **GitHub (镜像)**: https://github.com/VenceGuo/VenceBuddy

## License

MIT
