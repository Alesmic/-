@echo off
setlocal EnableDelayedExpansion
:: ==========================================
::  GIT 智能提交版 (中文环境优化)
:: ==========================================

echo [1/4] 检查状态...
git status --short

:: 检查是否有文件变动
for /f "delims=" %%i in ('git status --short') do set "hasChanges=1"

if defined hasChanges (
    echo.
    echo [2/4] 检测到文件变动，正在添加...
    git add .
    
    echo.
    echo [3/4] 提交到本地...
    set /p "msg=请输入提交备注 (回车默认 'Auto Update'): "
    if "!msg!"=="" set "msg=Auto Update"
    git commit -m "!msg!"
) else (
    echo.
    echo [跳过] 没有检测到新修改的文件，跳过提交步骤。
)

echo.
echo [4/4] 检查远程同步状态...
:: 检查是否有未推送的提交
git status | findstr "ahead" >nul
if %errorlevel% equ 0 (
    echo.
    echo =========================================
    echo  检测到本地有代码尚未推送到服务器！
    echo =========================================
    set /p "pushChoice=是否立即推送? (输入 y 确认): "
    if /i "!pushChoice!"=="y" (
        echo 正在推送...
        git push
        echo 推送完成！
    ) else (
        echo 已取消推送。
    )
) else (
    echo.
    echo 本地代码已是最新，无需推送。
)

echo.
pause