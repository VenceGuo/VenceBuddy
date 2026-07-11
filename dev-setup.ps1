# ============================================================
# VenceBuddy - 本地开发环境初始化脚本
# ============================================================
# 功能：
#   1. 检查/安装 Git 和 Node.js
#   2. 从 Gitee 克隆仓库到桌面
#   3. 配置双远端（Gitee 主 + GitHub 镜像）
#   4. 自动处理分支差异（Gitee=master, GitHub=main）
#   5. 创建 .env 配置文件
#   6. 安装 npm 依赖（国内源）
#   7. 验证环境
#
# 使用方式：在 PowerShell 中运行
#   .\dev-setup.ps1
# ============================================================

$ErrorActionPreference = "Stop"

# ---- 配置 ----
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ProjectName = "VenceBuddy"
$ProjectPath = Join-Path $DesktopPath $ProjectName
$GiteeUrl = "https://gitee.com/VenceGuo/VenceBuddy.git"
$GitHubUrl = "https://github.com/VenceGuo/VenceBuddy.git"

function Write-Step($msg) { Write-Host "`n========== $msg ==========" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [!] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "  [X] $msg" -ForegroundColor Red }

# ============================================================
# Step 1: 检查 Git
# ============================================================
Write-Step "Step 1/7: 检查 Git"

$gitPath = Get-Command git -ErrorAction SilentlyContinue
if ($gitPath) {
    Write-OK "Git: $(git --version)"
} else {
    Write-Warn "Git 未安装，正在通过 winget 安装..."
    winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements --silent
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $gitPath = Get-Command git -ErrorAction SilentlyContinue
    if ($gitPath) {
        Write-OK "Git 安装成功: $(git --version)"
    } else {
        Write-Err "Git 安装失败，请手动安装: https://git-scm.com/download/win"
        exit 1
    }
}

# 配置 git 全局用户信息（如果未设置）
$gitName = git config --global user.name
$gitEmail = git config --global user.email
if (-not $gitName) {
    $name = Read-Host "  请输入 Git 用户名 (如 VenceGuo)"
    git config --global user.name $name
    Write-OK "已设置 user.name = $name"
} else {
    Write-OK "Git user.name = $gitName"
}
if (-not $gitEmail) {
    $email = Read-Host "  请输入 Git 邮箱"
    git config --global user.email $email
    Write-OK "已设置 user.email = $email"
} else {
    Write-OK "Git user.email = $gitEmail"
}

# 配置 git 行尾（Windows）
git config --global core.autocrlf true
Write-OK "已设置 core.autocrlf = true (Windows)"

# ============================================================
# Step 2: 克隆仓库
# ============================================================
Write-Step "Step 2/7: 克隆仓库到桌面"

if (Test-Path $ProjectPath) {
    Write-Warn "目标目录已存在: $ProjectPath"
    $choice = Read-Host "  是否覆盖？(y/N)"
    if ($choice -eq "y" -or $choice -eq "Y") {
        Remove-Item $ProjectPath -Recurse -Force
        Write-OK "已删除旧目录"
    } else {
        Write-Warn "使用现有目录，跳过克隆"
        Set-Location $ProjectPath
        $skipClone = $true
    }
}

if (-not $skipClone) {
    Write-Host "  正在从 Gitee 克隆（国内速度快）..." -ForegroundColor DarkGray
    git clone $GiteeUrl $ProjectPath
    if ($LASTEXITCODE -eq 0) {
        Write-OK "克隆成功: $ProjectPath"
    } else {
        Write-Err "克隆失败，请检查网络或仓库地址: $GiteeUrl"
        exit 1
    }
    Set-Location $ProjectPath
}

# ============================================================
# Step 3: 检测分支并统一为 main
# ============================================================
Write-Step "Step 3/7: 检测分支"

$currentBranch = git branch --show-current 2>$null
if (-not $currentBranch) {
    $currentBranch = git rev-parse --abbrev-ref HEAD
}
Write-OK "当前分支: $currentBranch"

# 如果是 master，重命名为 main（统一两个平台的分支名）
if ($currentBranch -eq "master") {
    Write-Warn "Gitee 默认分支是 master，正在重命名为 main（与 GitHub 统一）..."
    git branch -m master main
    if ($LASTEXITCODE -eq 0) {
        Write-OK "本地分支已重命名: master -> main"
        # 推送新分支到 Gitee 并设为默认
        git push -u origin main
        # 删除 Gitee 上的旧 master 分支（等 main 设为默认后）
        Write-Warn "请在 Gitee 网页上将默认分支改为 main: 仓库管理 -> 默认分支"
    } else {
        Write-Err "分支重命名失败"
    }
} elseif ($currentBranch -eq "main") {
    Write-OK "分支已是 main，无需调整"
} else {
    Write-Warn "当前分支: $currentBranch，建议使用 main"
}

# ============================================================
# Step 4: 配置双远端
# ============================================================
Write-Step "Step 4/7: 配置 Git 远端"

# origin -> Gitee (主远端)
$originUrl = git remote get-url origin 2>$null
if ($originUrl -and $originUrl -ne $GiteeUrl) {
    git remote set-url origin $GiteeUrl
    Write-OK "已更新 origin -> Gitee"
} elseif ($originUrl -eq $GiteeUrl) {
    Write-OK "origin -> Gitee (已配置)"
} else {
    git remote add origin $GiteeUrl
    Write-OK "已添加 origin -> Gitee"
}

# github -> GitHub (镜像远端)
$githubUrl = git remote get-url github 2>$null
if ($githubUrl) {
    if ($githubUrl -ne $GitHubUrl) {
        git remote set-url github $GitHubUrl
    }
    Write-OK "github -> GitHub (已配置)"
} else {
    git remote add github $GitHubUrl
    Write-OK "已添加 github -> GitHub"
}

# 设置 push.default 为 current（推送当前分支到同名分支）
git config push.default current

# 显示远端配置
Write-Host "`n  远端配置:" -ForegroundColor DarkGray
git remote -v | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

# ============================================================
# Step 5: 创建 .env 配置文件
# ============================================================
Write-Step "Step 5/7: 创建 .env 配置文件"

$envFile = Join-Path $ProjectPath ".env"
$envExample = Join-Path $ProjectPath ".env.example"

if (Test-Path $envFile) {
    Write-Warn ".env 已存在，跳过创建"
} else {
    if (Test-Path $envExample) {
        Copy-Item $envExample $envFile
        Write-OK "已从 .env.example 创建 .env"
    } else {
        @"
# VenceBuddy - 环境变量配置（此文件不会被提交到 git）

# ---- Git Tokens ----
GITHUB_TOKEN=your_github_token_here
GITEE_TOKEN=your_gitee_token_here

# ---- LLM API Keys ----
DEEPSEEK_API_KEY=your_deepseek_api_key_here

# ---- Video Generation ----
SEEDDANCE_API_KEY=your_seeddance_api_key_here

# ---- Optional ----
DEEPSEEK_MODEL=deepseek-chat
SEEDDANCE_API_BASE=https://api.seeddance.ai/v1
"@ | Out-File -FilePath $envFile -Encoding utf8
        Write-OK "已创建 .env"
    }
    Write-Host "`n  请编辑 .env 填入真实 Token:" -ForegroundColor Yellow
    Write-Host "    notepad .env   或   code .env" -ForegroundColor DarkGray
}

# 确保 .env 在 .gitignore 中
$gitignoreContent = Get-Content (Join-Path $ProjectPath ".gitignore") -ErrorAction SilentlyContinue -Raw
if ($gitignoreContent -notmatch "^\.env$") {
    Add-Content (Join-Path $ProjectPath ".gitignore") "`n# Environment variables`n.env`n.env.local`n.env.*.local"
    Write-OK "已将 .env 添加到 .gitignore"
} else {
    Write-OK ".env 已在 .gitignore 中（安全）"
}

# 验证 .env 未被 git 跟踪
$envTracked = git ls-files --cached ".env" 2>$null
if ($envTracked) {
    Write-Warn ".env 被 git 跟踪了！正在移除..."
    git rm --cached .env
    Write-OK "已从 git 跟踪中移除 .env"
}

# ============================================================
# Step 6: 安装 npm 依赖
# ============================================================
Write-Step "Step 6/7: 安装 npm 依赖"

$nodePath = Get-Command node -ErrorAction SilentlyContinue
if ($nodePath) {
    Write-OK "Node.js: $(node --version)"
} else {
    Write-Warn "Node.js 未安装，正在通过 winget 安装 LTS 版..."
    winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements --silent
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $nodePath = Get-Command node -ErrorAction SilentlyContinue
    if ($nodePath) {
        Write-OK "Node.js 安装成功: $(node --version)"
    } else {
        Write-Err "Node.js 安装失败，请手动安装: https://nodejs.org/"
        Write-Warn "安装后重新运行此脚本"
        exit 1
    }
}

# 切换 npm 国内源
$npmRegistry = npm config get registry
if ($npmRegistry -notmatch "npmmirror") {
    Write-Warn "当前 npm 源: $npmRegistry，切换到国内镜像..."
    npm config set registry https://registry.npmmirror.com
    Write-OK "npm 源 -> registry.npmmirror.com"
} else {
    Write-OK "npm 源已是国内镜像"
}

# 安装依赖
Write-Host "  正在安装依赖（可能需要几分钟）..." -ForegroundColor DarkGray
npm install
if ($LASTEXITCODE -eq 0) {
    Write-OK "npm 依赖安装完成"
} else {
    Write-Err "npm install 失败"
    Write-Warn "可尝试: rm -rf node_modules package-lock.json && npm install"
    exit 1
}

# ============================================================
# Step 7: 验证 + 总结
# ============================================================
Write-Step "Step 7/7: 验证开发环境"

$allGood = $true

$checks = @(
    @{ name = "Git";       cmd = { git --version } },
    @{ name = "Node.js";   cmd = { node --version } },
    @{ name = "npm";       cmd = { npm --version } }
)

foreach ($check in $checks) {
    try {
        $ver = & $check.cmd 2>&1
        Write-OK "$($check.name): $ver"
    } catch {
        Write-Err "$($check.name) 不可用"
        $allGood = $false
    }
}

# 远端检查
$remotes = git remote -v 2>$null
if ($remotes -match "gitee") { Write-OK "Gitee 远端: 已配置" } else { Write-Err "Gitee 远端未配置"; $allGood = $false }
if ($remotes -match "github") { Write-OK "GitHub 远端: 已配置" } else { Write-Err "GitHub 远端未配置"; $allGood = $false }

# 文件检查
if (Test-Path (Join-Path $ProjectPath ".env")) { Write-OK ".env: 已创建" } else { Write-Err ".env 不存在"; $allGood = $false }
if (Test-Path (Join-Path $ProjectPath "node_modules")) { Write-OK "node_modules: 已安装" } else { Write-Err "node_modules 不存在"; $allGood = $false }

# 分支检查
$branch = git branch --show-current 2>$null
if ($branch -eq "main") { Write-OK "分支: main" } else { Write-Warn "分支: $branch（建议用 main）" }

# ============================================================
# 完成提示
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "  VenceBuddy 本地开发环境已就绪！" -ForegroundColor Green
} else {
    Write-Host "  部分配置未完成，请检查上方 [X] 标记" -ForegroundColor Yellow
}
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  项目路径: $ProjectPath" -ForegroundColor White
Write-Host ""
Write-Host "  下一步:" -ForegroundColor White
Write-Host "    1. 编辑 .env 填入真实 Token:" -ForegroundColor DarkGray
Write-Host "       notepad .env" -ForegroundColor DarkGray
Write-Host ""
Write-Host "    2. 启动开发服务器:" -ForegroundColor DarkGray
Write-Host "       npm run dev" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  日常 Git 工作流:" -ForegroundColor White
Write-Host "    git add .                              # 暂存改动" -ForegroundColor DarkGray
Write-Host "    git commit -m 'feat: xxx'              # 提交" -ForegroundColor DarkGray
Write-Host "    git push origin main                   # 推到 Gitee（主）" -ForegroundColor DarkGray
Write-Host "    git push github main                   # 同步到 GitHub（镜像）" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  拉取最新代码:" -ForegroundColor White
Write-Host "    git pull origin main                   # 从 Gitee 拉取" -ForegroundColor DarkGray
Write-Host ""
if ($currentBranch -eq "master") {
    Write-Host "  注意: Gitee 默认分支仍是 master，建议去网页改为 main:" -ForegroundColor Yellow
    Write-Host "    https://gitee.com/VenceGuo/VenceBuddy/branches" -ForegroundColor DarkGray
    Write-Host ""
}
Write-Host "============================================================" -ForegroundColor Cyan
