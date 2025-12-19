@echo off
:: ==========================================
::  GIT 极简稳定版 (无颜色，防闪退)
:: ==========================================

echo [1/5] 正在检查运行环境...
echo 当前运行目录: %cd%

:: 检查是否安装了 git
git --version
if %errorlevel% neq 0 (
    echo [错误] 电脑上没找到 git 命令！请先安装 Git。
    pause
    exit
)

echo.
echo [2/5] 正在添加到暂存区 (git add)...
git add .

echo.
echo [3/5] 提交代码
set /p "msg=请输入提交备注 (直接回车默认使用 Auto update): "
if "%msg%"=="" set "msg=Auto update"

echo 正在提交: "%msg%"
git commit -m "%msg%"

echo.
echo [4/5] 准备推送到远程仓库...
set /p "shouldPush=是否推送? (输入 y 确认，其他键跳过): "
if /i "%shouldPush%"=="y" (
    echo 正在推送 (git push)...
    git push
) else (
    echo 已跳过推送。
)

echo.
echo [5/5] 脚本运行结束。
echo ==========================================
pause