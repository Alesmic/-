@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: =========================================================
::  GIT 自动化工具 - 中文完美支持版 (UTF-8)
::  修复了中文备注乱码问题
:: =========================================================

:: 1. 强制切换到 UTF-8 编码 (解决 Git 中文乱码的核心)
chcp 65001 >nul

:: 2. 生成颜色代码
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set "ESC=%%b"
)

set "RESET=%ESC%[0m"
set "BOLD=%ESC%[1m"
set "CYAN=%ESC%[36m"
set "MAGENTA=%ESC%[35m"
set "YELLOW=%ESC%[33m"
set "GREEN=%ESC%[32m"
set "RED=%ESC%[31m"
set "BLUE=%ESC%[34m"

:: 设置窗口
title Git Pro [CN] - UTF8 Mode
mode con: cols=90 lines=30

:: ---------------------------------------------------------
:: 3. 经典界面
:: ---------------------------------------------------------
cls
echo.
echo  %CYAN%%BOLD%   ______   __   ______      ______   ______   ______     %RESET%
echo  %CYAN%%BOLD%  /\  ___\ /\ \ /\__  _\    /\  __ \ /\  __ \ /\__  _\    %RESET%
echo  %CYAN%%BOLD%  \ \ \__ \\ \ \\/_/\ \/    \ \  __ \\ \ \/\ \\/_/\ \/    %RESET%
echo  %CYAN%%BOLD%   \ \_____\\ \_\  \ \_\     \ \_\ \_\\ \_____\  \ \_\    %RESET%
echo  %CYAN%%BOLD%    \/_____/ \/_/   \/_/      \/_/\/_/  \/_____/   \/_/    %RESET%
echo.
echo          %YELLOW%^^^>^^^>  自 动 化 版 本 控 制 系 统  ^^^<^^^<%RESET%
echo.
echo          %MAGENTA%Dev and Design by: xyhyxu%RESET%
echo.

echo  %BLUE%   [系统初始化] 正在加载模块...%RESET%
:: 使用 ping 做延时，兼容性最好
ping 127.0.0.1 -n 2 >nul
echo  %GREEN%   [OK] 就绪%RESET%
echo.

:: ---------------------------------------------------------
:: 4. 环境检查
:: ---------------------------------------------------------
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo  %RED%[错误] 未找到 Git 命令！%RESET%
    pause
    exit /b
)

if not exist .git (
    echo  %RED%[错误] 当前目录不是 Git 仓库。%RESET%
    pause
    exit /b
)

:: ---------------------------------------------------------
:: 5. 状态扫描
:: ---------------------------------------------------------
echo  %BLUE%[%time:~0,8%]%RESET% %BOLD%正在扫描工作区...%RESET%

:: 获取分支
for /f "tokens=*" %%i in ('git branch --show-current') do set "BRANCH=%%i"
echo  %CYAN%[信息]%RESET% 当前分支: %GREEN%!BRANCH!%RESET%

:: 检测变动
set "HAS_CHANGES=0"
for /f "delims=" %%i in ('git status --short') do set "HAS_CHANGES=1"

if "!HAS_CHANGES!"=="1" goto :FoundChanges
goto :NoChanges

:FoundChanges
    echo  %CYAN%[信息]%RESET% 检测到文件变动，准备提交...
    echo.
    echo  %MAGENTA%==================================================================%RESET%
    echo   正在执行: git add .
    echo  %MAGENTA%==================================================================%RESET%
    git add .
    
    echo.
    echo  %YELLOW% 请输入提交备注 (中文/英文均可):%RESET%
    echo  %MAGENTA%==================================================================%RESET%
    set "MSG="
    set /p "MSG=%CYAN% > %RESET%"
    
    if "!MSG!"=="" set "MSG=Update by xyhyxu [%date%]"
    
    echo.
    :: 再次确认编码，防止输入法干扰
    chcp 65001 >nul
    echo  %BLUE%[%time:~0,8%]%RESET% %BOLD%正在提交: "!MSG!"%RESET%
    git commit -m "!MSG!"
    goto :CheckPush

:NoChanges
    echo.
    echo  %GREEN%[OK] 工作区很干净，没有新文件。%RESET%
    goto :CheckPush

:: ---------------------------------------------------------
:: 6. 推送检查
:: ---------------------------------------------------------
:CheckPush
echo.
echo  %BLUE%[%time:~0,8%]%RESET% %BOLD%检查远程同步状态...%RESET%

git status | findstr "ahead" >nul
if %errorlevel% equ 0 goto :NeedPush
goto :UpToDate

:NeedPush
    echo.
    echo  %RED%[提醒] 本地有代码尚未推送到服务器！%RESET%
    echo.
    echo  %MAGENTA%------------------------------------------------------------------%RESET%
    set "PUSH_CHOICE="
    set /p "PUSH_CHOICE=%YELLOW%[操作] 是否立即推送? (输入 Y 确认): %RESET%"
    
    if /i "!PUSH_CHOICE!"=="y" (
        echo.
        echo  %BLUE%[%time:~0,8%]%RESET% %BOLD%正在推送 (git push)...%RESET%
        git push
        
        if !errorlevel! equ 0 (
            echo.
            echo  %GREEN%[成功] 代码已成功同步到远程仓库！%RESET%
        ) else (
            echo.
            echo  %RED%[失败] 推送出错了，请检查网络。%RESET%
        )
    ) else (
        echo  [信息] 已跳过推送。
    )
    goto :End

:UpToDate
    echo  %GREEN%[OK] 代码已是最新，无需推送。%RESET%
    goto :End

:: ---------------------------------------------------------
:: 7. 结束
:: ---------------------------------------------------------
:End
echo.
echo  %MAGENTA%==================================================================%RESET%
echo  %GREEN%               操作完成，感谢使用 Git Auto Tool                   %RESET%
echo  %MAGENTA%==================================================================%RESET%
echo.
echo  按任意键退出...
pause >nul