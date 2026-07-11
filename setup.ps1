# ============================================================
# VenceBuddy - 一键初始化脚本（安全版，不含 Token）
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host "`n=== VenceBuddy 项目初始化 ===`n" -ForegroundColor Cyan

# --- 配置 ---
$GITEE_USER = "VenceGuo"
$GITHUB_USER = "VenceGuo"
$PROJECT_NAME = "VenceBuddy"

# --- 输入 Token ---
Write-Host "请输入 Gitee Token (https://gitee.com/profile/personal_access_tokens):" -ForegroundColor Yellow
$GITEE_TOKEN = Read-Host "Gitee Token"
Write-Host "请输入 GitHub Token (需要 Contents: Read and write 权限):" -ForegroundColor Yellow
$GITHUB_TOKEN = Read-Host "GitHub Token"

if ([string]::IsNullOrWhiteSpace($GITEE_TOKEN) -or [string]::IsNullOrWhiteSpace($GITHUB_TOKEN)) {
    Write-Host "Token 不能为空！" -ForegroundColor Red
    exit 1
}

# --- 1. 检查并安装 git ---
Write-Host "`n[1/5] 检查 Git..." -ForegroundColor Yellow
$gitPath = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitPath) {
    Write-Host "Git 未安装！正在安装..." -ForegroundColor Red
    winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements --silent
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    $gitPath = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitPath) {
        Write-Host "Git 安装失败，请手动安装: https://git-scm.com/download/win" -ForegroundColor Red
        exit 1
    }
}
Write-Host "Git: $(git --version)" -ForegroundColor Green

# --- 2. 从 Gitee 克隆 ---
Write-Host "`n[2/5] 从 Gitee 拉取代码..." -ForegroundColor Yellow
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $SCRIPT_DIR

git init
git config user.name "VenceGuo"
git config user.email "VenceGuo@users.noreply.github.com"

git remote add origin "https://${GITEE_USER}:${GITEE_TOKEN}@gitee.com/${GITEE_USER}/${PROJECT_NAME}.git"
git fetch origin
git checkout -b main origin/master 2>$null
if ($LASTEXITCODE -ne 0) { git checkout -b main origin/main 2>$null }
Write-Host "代码拉取完成" -ForegroundColor Green

# --- 3. 配置远端 ---
Write-Host "`n[3/5] 配置远程仓库..." -ForegroundColor Yellow

git remote remove origin 2>$null
git remote add origin "https://${GITEE_USER}:${GITEE_TOKEN}@gitee.com/${GITEE_USER}/${PROJECT_NAME}.git"
Write-Host "  Gitee (origin):  https://gitee.com/${GITEE_USER}/${PROJECT_NAME}" -ForegroundColor Green

git remote remove github 2>$null
git remote add github "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${PROJECT_NAME}.git"
Write-Host "  GitHub (mirror): https://github.com/${GITHUB_USER}/${PROJECT_NAME}" -ForegroundColor Green

git remote remove upstream 2>$null
git remote add upstream "https://github.com/anthropics/openclaw.git"
Write-Host "  Upstream:        https://github.com/anthropics/openclaw" -ForegroundColor Green

# --- 4. 设置默认推送 ---
Write-Host "`n[4/5] 配置默认推送..." -ForegroundColor Yellow
git config remote.origin.pushurl "https://${GITEE_USER}:${GITEE_TOKEN}@gitee.com/${GITEE_USER}/${PROJECT_NAME}.git"
Write-Host "默认推送: origin (Gitee)" -ForegroundColor Green

# --- 5. 完成 ---
Write-Host "`n[5/5] 初始化完成!" -ForegroundColor Cyan
Write-Host "`n仓库地址:" -ForegroundColor White
Write-Host "  Gitee:  https://gitee.com/${GITEE_USER}/${PROJECT_NAME}" -ForegroundColor Gray
Write-Host "  GitHub: https://github.com/${GITHUB_USER}/${PROJECT_NAME}" -ForegroundColor Gray
Write-Host "`n日常开发:" -ForegroundColor White
Write-Host "  git add . && git commit -m 'your message'" -ForegroundColor Gray
Write-Host "  git push origin main    # 推到 Gitee (主)" -ForegroundColor Gray
Write-Host "  git push github main    # 同步到 GitHub (镜像)" -ForegroundColor Gray
Write-Host "  git fetch upstream      # 拉取 OpenClaw 上游更新" -ForegroundColor Gray
Write-Host "`n"
