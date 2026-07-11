# ============================================================
# VenceBuddy - GitHub 同步脚本
# Gitee 代码已推送完成，此脚本用于同步到 GitHub
#
# 前提条件：
#   1. 已更新 GitHub Token 权限（Contents: Read and write）
#   2. 打开 https://github.com/settings/tokens
#   3. 找到你的 Fine-grained token → 点击编辑
#   4. Repository permissions → Contents → 设为 "Read and write"
#   5. 保存
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host "`n=== VenceBuddy GitHub 同步 ===`n" -ForegroundColor Cyan

# --- 配置 ---
$GITEE_USER = "VenceGuo"
$GITHUB_USER = "VenceGuo"
$PROJECT_NAME = "VenceBuddy"

# 输入新的 GitHub Token
Write-Host "请输入更新后的 GitHub Token (Contents: Read and write):" -ForegroundColor Yellow
$GITHUB_TOKEN = Read-Host "Token"

if ([string]::IsNullOrWhiteSpace($GITHUB_TOKEN)) {
    Write-Host "Token 不能为空！" -ForegroundColor Red
    exit 1
}

# --- 1. 检查 git ---
Write-Host "`n[1/5] 检查 Git..." -ForegroundColor Yellow
$gitPath = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitPath) {
    Write-Host "Git 未安装！正在通过 winget 安装..." -ForegroundColor Red
    winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements --silent
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    $gitPath = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitPath) {
        Write-Host "Git 安装失败，请手动安装: https://git-scm.com/download/win" -ForegroundColor Red
        exit 1
    }
}
Write-Host "Git: $(git --version)" -ForegroundColor Green

# --- 2. 克隆 Gitee 仓库 ---
$WORK_DIR = "$env:TEMP\VenceBuddy_sync"
Write-Host "`n[2/5] 从 Gitee 克隆代码..." -ForegroundColor Yellow

if (Test-Path $WORK_DIR) {
    Remove-Item $WORK_DIR -Recurse -Force
}

git clone "https://${GITEE_USER}:53b15e40b7e85696ce09b6a500bb48e7@gitee.com/${GITEE_USER}/${PROJECT_NAME}.git" $WORK_DIR
if ($LASTEXITCODE -ne 0) {
    Write-Host "Gitee 克隆失败！" -ForegroundColor Red
    exit 1
}
Write-Host "克隆成功" -ForegroundColor Green

Set-Location $WORK_DIR
git branch -M main
git config user.name "VenceGuo"
git config user.email "VenceGuo@users.noreply.github.com"

# --- 3. 配置 GitHub 远端 ---
Write-Host "`n[3/5] 配置 GitHub 远端..." -ForegroundColor Yellow
git remote add github "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${PROJECT_NAME}.git"
Write-Host "GitHub remote 已配置" -ForegroundColor Green

# --- 4. 推送到 GitHub ---
Write-Host "`n[4/5] 推送到 GitHub..." -ForegroundColor Yellow
$pushResult = git push github main 2>&1
Write-Host $pushResult

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nGitHub 推送成功！" -ForegroundColor Green
} else {
    Write-Host "`nGitHub 推送失败！" -ForegroundColor Red
    Write-Host "请确认:" -ForegroundColor Yellow
    Write-Host "  1. Token 已更新为包含 Contents: Read and write 权限" -ForegroundColor Yellow
    Write-Host "  2. GitHub 仓库 VenceBuddy 已创建: https://github.com/new" -ForegroundColor Yellow
    exit 1
}

# --- 5. 清理 ---
Write-Host "`n[5/5] 清理临时文件..." -ForegroundColor Yellow
Set-Location $env:TEMP
Remove-Item $WORK_DIR -Recurse -Force -ErrorAction SilentlyContinue

# --- 完成 ---
Write-Host "`n=== 同步完成! ===" -ForegroundColor Cyan
Write-Host "`n仓库地址:" -ForegroundColor White
Write-Host "  Gitee:  https://gitee.com/${GITEE_USER}/${PROJECT_NAME}" -ForegroundColor Gray
Write-Host "  GitHub: https://github.com/${GITHUB_USER}/${PROJECT_NAME}" -ForegroundColor Gray
Write-Host "`n后续日常开发:" -ForegroundColor White
Write-Host "  cd C:\path\to\VenceBuddy" -ForegroundColor Gray
Write-Host "  git add . && git commit -m 'your message'" -ForegroundColor Gray
Write-Host "  git push origin main    # 推到 Gitee (主)" -ForegroundColor Gray
Write-Host "  git push github main    # 同步到 GitHub (镜像)" -ForegroundColor Gray
Write-Host "`n"
