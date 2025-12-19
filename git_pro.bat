@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: =========================================================
::  GIT 自动化工具 - GBK 专用稳定版
::  注册给: xyhyxu
:: =========================================================

:: 1. 生成颜色代码 (兼容 GBK)
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
title Git Pro [CN] - Powered by xyhyxu
mode con: cols=85 lines=30

:: ---------------------------------------------------------
:: 2. 启动动画
:: ---------------------------------------------------------
cls
echo.
echo  %CYAN%   *****************************************%RESET%
echo  %CYAN%   * *%RESET%
echo  %CYAN%   * %BOLD%GIT 自 动 化 同 步 系 统  V 4 . 0%RESET%%CYAN%   *%RESET%
echo  %CYAN%   * *%RESET%
echo  %CYAN%   *****************************************%RESET%
echo         %MAGENTA%Designed by: xyhyxu (Dev and Design)%RESET%
echo.

:: 简单的加载条 (防止 GBK 环境下乱码崩溃)
<nul set /p "=%BLUE%[系统初始化] %RESET%"
for /L %%i in (1,1,25) do (
    <nul set /p "=%GREEN%#%RESET%"
    for /L %%j in (1,1,100) do rem
)
echo  %GREEN% [完成]%RESET%
echo.

:: ---------------------------------------------------------
:: 3. 环境检查
:: ---------------------------------------------------------
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo  %RED%[错误] 没找到 Git 命令！请先安装 Git。%RESET%
    pause
    exit /b
)

if not exist .git (
    echo  %RED%[错误] 当前目录没有 .git 文件夹。%RESET%
    echo  请把脚本放在项目根目录下。
    pause
    exit /b
)

:: ---------------------------------------------------------
:: 4. 状态扫描
:: ---------------------------------------------------------
echo  %MAGENTA%[%time:~0,8%]%RESET% 正在扫描工作区...

:: 获取分支
for /f "tokens=*" %%i in ('git branch --show-current') do set "BRANCH=%%i"
echo  %CYAN%[信息]%RESET% 当前分支: %GREEN%!BRANCH!%RESET%

:: 检测变动
set "HAS_CHANGES=0"
for /f "delims=" %%i in ('git status --short') do set "HAS_CHANGES=1"

if "!HAS_CHANGES!"=="1" goto :FoundChanges
goto :NoChanges

:FoundChanges
    echo  %CYAN%[信息]%RESET% 发现新文件，准备提交...
    echo.
    echo  %YELLOW%=========================================%RESET%
    echo     正在执行: git add .
    echo  %YELLOW%=========================================%RESET%
    git add .
    
    echo.
    echo  %GREEN%请输入提交备注 (直接回车使用默认值):%RESET%
    set "MSG="
    set /p "MSG=%CYAN% > %RESET%"
    
    if "!MSG!"=="" set "MSG=Update by xyhyxu [%date%]"
    
    echo.
    echo  %MAGENTA%[%time:~0,8%]%RESET% 正在提交...
    git commit -m "!MSG!"
    goto :CheckPush

:NoChanges
    echo.
    echo  %GREEN%[OK] 工作区很干净，没有新文件。%RESET%
    goto :CheckPush

:: ---------------------------------------------------------
:: 5. 推送检查
:: ---------------------------------------------------------
:CheckPush
echo.
echo  %MAGENTA%[%time:~0,8%]%RESET% 检查远程同步...

git status | findstr "ahead" >nul
if %errorlevel% equ 0 goto :NeedPush
goto :UpToDate

:NeedPush
    echo.
    echo  %RED%[提醒] 本地有代码还没推送到服务器！%RESET%
    echo.
    set "PUSH_CHOICE="
    set /p "PUSH_CHOICE=%YELLOW%[操作] 是否立即推送? (输入 Y 确认): %RESET%"
    
    if /i "!PUSH_CHOICE!"=="y" (
        echo.
        echo  %BLUE%=========================================%RESET%
        echo     正在推送: git push origin !BRANCH!
        echo  %BLUE%=========================================%RESET%
        git push
        
        if !errorlevel! equ 0 (
            echo.
            echo  %GREEN%[成功] 推送完成！%RESET%
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
:: 6. 结束
:: ---------------------------------------------------------
:End
echo.
echo  %CYAN%___________________________________________________%RESET%
echo.
echo       %GREEN%所有操作已完成。%RESET%
echo            %YELLOW%祝您愉快，xyhyxu！%RESET%
echo.
pause