# ============================================================
# VenceBuddy - 本地开发环境初始化脚本
# ============================================================
# 功能：
#   1. 检查/安装 Git
#   2. 从 Gitee 克隆仓库到桌面
#   3. 配置双远端（Gitee 主 + GitHub 镜像）
#   4. 创建 .env 配置文件
#   5. 安装 npm 依赖（切换国内源）
#   6. 验证环境
#
# 使用方式：在 PowerShell 中运行
#   cd C:\Users\44364\WorkBuddy\2026-07-11-23-08-42\VenceBuddy
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
Write-Step "Step 1/6: 检查 Git"

$gitPath = Get-Command git -ErrorAction SilentlyContinue
if ($gitPath) {
    $gitVer = git --version
    Write-OK "Git 已安装: $gitVer"
} else {
    Write-Warn "Git 未安装，正在通过 winget 安装..."
    winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements --silent
    # 刷新 PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $gitPath = Get-Command git -ErrorAction SilentlyContinue
    if ($gitPath) {
        Write-OK "Git 安装成功: $(git --version)"
    } else {
        Write-Err "Git 安装失败，请手动安装: https://git-scm.com/download/win"
        exit 1
    }
}

# 检查 git 全局配置
$gitName = git config --global user.name
$gitEmail = git config --global user.email
if (-not $gitName) {
    Write-Warn "Git user.name 未设置"
    $name = Read-Host "  请输入你的 Git 用户名 (如 VenceGuo)"
    git config --global user.name $name
    Write-OK "已设置 user.name = $name"
} else {
    Write-OK "Git user.name = $gitName"
}
if (-not $gitEmail) {
    Write-Warn "Git user.email 未设置"
    $email = Read-Host "  请输入你的 Git 邮箱"
    git config --global user.email $email
    Write-OK "已设置 user.email = $email"
} else {
    Write-OK "Git user.email = $gitEmail"
}

# ============================================================
# Step 2: 克隆仓库
# ============================================================
Write-Step "Step 2/6: 克隆仓库到桌面"

if (Test-Path $ProjectPath) {
    Write-Warn "目标目录已存在: $ProjectPath"
    $choice = Read-Host "  是否覆盖？(y/N)"
    if ($choice -eq "y" -or $choice -eq "Y") {
        Remove-Item $ProjectPath -Recurse -Force
        Write-OK "已删除旧目录"
    } else {
        Write-Warn "跳过克隆，使用现有目录: $ProjectPath"
        Set-Location $ProjectPath
        # 确保远端配置正确
        $origin = git remote get-url origin 2>$null
        if ($origin) {
            Write-OK "origin 远端已存在: $origin"
        } else {
            git remote add origin $GiteeUrl
            Write-OK "已添加 origin 远端: $GiteeUrl"
        }
        # 跳到 Step 3
        goto step3
    }
}

Write-Host "  正在从 Gitee 克隆（国内速度快）..."
git clone $GiteeUrl $ProjectPath
if ($LASTEXITCODE -eq 0) {
    Write-OK "克隆成功: $ProjectPath"
} else {
    Write-Err "克隆失败，请检查 Gitee 仓库地址: $GiteeUrl"
    exit 1
}

Set-Location $ProjectPath

# ============================================================
# Step 3: 配置双远端
# ============================================================
:step3
Write-Step "Step 3/6: 配置 Git 远端"

# origin -> Gitee (主远端)
$originUrl = git remote get-url origin 2>$null
if ($originUrl -and $originUrl -ne $GiteeUrl) {
    git remote set-url origin $GiteeUrl
    Write-OK "已更新 origin -> $GiteeUrl"
} elseif ($originUrl -eq $GiteeUrl) {
    Write-OK "origin 已指向 Gitee: $GiteeUrl"
} else {
    git remote add origin $GiteeUrl
    Write-OK "已添加 origin (Gitee): $GiteeUrl"
}

# github -> GitHub (镜像远端)
$githubUrl = git remote get-url github 2>$null
if ($githubUrl) {
    if ($githubUrl -ne $GitHubUrl) {
        git remote set-url github $GitHubUrl
        Write-OK "已更新 github -> $GitHubUrl"
    } else {
        Write-OK "github 已指向 GitHub: $GitHubUrl"
    }
} else {
    git remote add github $GitHubUrl
    Write-OK "已添加 github (镜像): $GitHubUrl"
}

# 显示远端配置
Write-Host "`n  当前远端配置:" -ForegroundColor DarkGray
git remote -v | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

# ============================================================
# Step 4: 创建 .env 配置文件
# ============================================================
Write-Step "Step 4/6: 创建 .env 配置文件"

$envFile = Join-Path $ProjectPath ".env"
$envExample = Join-Path $ProjectPath ".env.example"

if (Test-Path $envFile) {
    Write-Warn ".env 文件已存在，跳过创建"
    Write-Host "  如需重新创建，请先删除 .env 文件" -ForegroundColor DarkGray
} else {
    if (Test-Path $envExample) {
        Copy-Item $envExample $envFile
        Write-OK "已从 .env.example 创建 .env"
    } else {
        # 直接创建
        @"
# VenceBuddy - 环境变量配置
# 此文件已被 .gitignore 忽略，不会被提交

# ---- Git Tokens ----
GITHUB_TOKEN=your_github_token_here
GITEE_TOKEN=your_gitee_token_here

# ---- LLM API Keys ----
DEEPSEEK_API_KEY=your_deepseek_api_key_here

# ---- Video Generation API Keys ----
SEEDDANCE_API_KEY=your_seeddance_api_key_here

# ---- Optional ----
DEEPSEEK_MODEL=deepseek-chat
SEEDDANCE_API_BASE=https://api.seeddance.ai/v1
"@ | Out-File -FilePath $envFile -Encoding utf8
        Write-OK "已创建 .env 文件"
    }

    Write-Host "`n  请编辑 .env 文件填入真实 Token:" -ForegroundColor Yellow
    Write-Host "    notepad .env" -ForegroundColor DarkGray
    Write-Host "  或用 VS Code:" -ForegroundColor DarkGray
    Write-Host "    code .env" -ForegroundColor DarkGray
}

# 验证 .env 在 .gitignore 中
$gitignoreContent = Get-Content (Join-Path $ProjectPath ".gitignore") -ErrorAction SilentlyContinue
if ($gitignoreContent -match "^\.env$") {
    Write-OK ".env 已在 .gitignore 中（不会被提交）"
} else {
    Write-Warn ".env 不在 .gitignore 中！正在添加..."
    Add-Content (Join-Path $ProjectPath ".gitignore") "`n# Environment variables`n.env`n.env.local`n.env.*.local"
    Write-OK "已将 .env 添加到 .gitignore"
}

# ============================================================
# Step 5: 安装 npm 依赖
# ============================================================
Write-Step "Step 5/6: 安装 npm 依赖"

# 检查 Node.js
$nodePath = Get-Command node -ErrorAction SilentlyContinue
if ($nodePath) {
    $nodeVer = node --version
    Write-OK "Node.js 已安装: $nodeVer"
} else {
    Write-Warn "Node.js 未安装，正在通过 winget 安装..."
    winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements --silent
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $nodePath = Get-Command node -ErrorAction SilentlyContinue
    if ($nodePath) {
        Write-OK "Node.js 安装成功: $(node --version)"
    } else {
        Write-Err "Node.js 安装失败，请手动安装: https://nodejs.org/"
        Write-Warn "安装后重新运行此脚本的 Step 5"
        exit 1
    }
}

# 切换 npm 国内源
$npmRegistry = npm config get registry
if ($npmRegistry -notmatch "npmmirror") {
    Write-Warn "当前 npm 源: $npmRegistry"
    Write-Host "  切换到国内淘宝镜像源..." -ForegroundColor DarkGray
    npm config set registry https://registry.npmmirror.com
    Write-OK "已切换 npm 源 -> registry.npmmirror.com"
} else {
    Write-OK "npm 源已是国内镜像: $npmRegistry"
}

# 安装依赖
Write-Host "  正在安装依赖（可能需要几分钟）..." -ForegroundColor DarkGray
npm install
if ($LASTEXITCODE -eq 0) {
    Write-OK "npm 依赖安装完成"
} else {
    Write-Err "npm install 失败"
    Write-Warn "尝试删除 node_modules 和 package-lock.json 后重试"
    exit 1
}

# ============================================================
# Step 6: 验证环境
# ============================================================
Write-Step "Step 6/6: 验证开发环境"

$allGood = $true

# 检查 git
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-OK "Git: $(git --version)"
} else { Write-Err "Git 不可用"; $allGood = $false }

# 检查 node
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-OK "Node.js: $(node --version)"
} else { Write-Err "Node.js 不可用"; $allGood = $false }

# 检查 npm
if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-OK "npm: $(npm --version)"
} else { Write-Err "npm 不可用"; $allGood = $false }

# 检查远端
$remotes = git remote -v 2>$null
if ($remotes -match "gitee") {
    Write-OK "Gitee 远端: 已配置"
} else { Write-Err "Gitee 远端未配置"; $allGood = $false }

if ($remotes -match "github") {
    Write-OK "GitHub 远端: 已配置"
} else { Write-Err "GitHub 远端未配置"; $allGood = $false }

# 检查 .env
if (Test-Path (Join-Path $ProjectPath ".env")) {
    Write-OK ".env 文件: 已创建"
} else { Write-Err ".env 文件不存在"; $allGood = $false }

# 检查 node_modules
if (Test-Path (Join-Path $ProjectPath "node_modules")) {
    Write-OK "node_modules: 已安装"
} else { Write-Err "node_modules 不存在"; $allGood = $false }

# 检查 .env 是否被 git 跟踪
$envTracked = git ls-files --cached ".env" 2>$null
if ($envTracked) {
    Write-Warn ".env 被 git 跟踪了！正在移除跟踪..."
    git rm --cached .env
    Write-OK "已从 git 跟踪中移除 .env"
} else {
    Write-OK ".env 未被 git 跟踪（安全）"
}

# ============================================================
# 完成
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
Write-Host "  接下来:" -ForegroundColor White
Write-Host "    1. 编辑 .env 填入真实 Token:" -ForegroundColor DarkGray
Write-Host "       notepad .env" -ForegroundColor DarkGray
Write-Host ""
Write-Host "    2. 启动开发服务器:" -ForegroundColor DarkGray
Write-Host "       npm run dev" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  日常开发 Git 工作流:" -ForegroundColor White
Write-Host "    git add ." -ForegroundColor DarkGray
Write-Host "    git commit -m 'feat: xxx'" -ForegroundColor DarkGray
Write-Host "    git push origin main       # 推到 Gitee（主）" -ForegroundColor DarkGray
Write-Host "    git push github main       # 同步到 GitHub（镜像）" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  从 Gitee 拉取最新代码:" -ForegroundColor White
Write-Host "    git pull origin main" -ForegroundColor DarkGray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
