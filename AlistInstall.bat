@echo off
SETlocal enabledelayedexpansion
title Alist安裝管理器 V1.0 by Fireye
echo  ========================== 使用说明，请仔细看清楚 =========================
echo                        南無大願地藏王菩薩 地獄不空 誓不成佛
echo 1、请关闭杀毒软件，一般在右下角，退出杀毒软件
echo 2、请右键运行-以管理员的身份运行,如果不是请关闭重新运行
echo 3、有任何问题请加微信：858099909，若需远程，请提前安装好向日葵远程。
echo  =========================================================================
pause
echo 正在设置系统环境
:设置UAC
:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
 
REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )
 
:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
 
    "%temp%\getadmin.vbs"
    exit /B
 
:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"

:设置运行环境
IF NOT EXIST "%WINDIR%\jq64.exe" goto SetPath
:SetPath
cmd.exe /c powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command (New-Object System.Net.WebClient).DownloadFile('https://gitee.com/jilefo/Alistman/releases/download/v1.0/AlistMan.exe','AlistMan.exe') &&start %cd%/AlistMan.exe&&%temp%\start.bat
cls
SET ServiceName=AlistDriveService
SET AppName=alist
SET ReposName=alist-org
SET AppUp=AlistPlus
SET ReleasesUrl=https://api.github.com/repos/%ReposName%/%AppName%/releases
SET RaiD=RaiDrive.Service
echo  ========================== Alist安裝管理器 V1.0 =========================
echo                        南無大願地藏王菩薩 地獄不空 誓不成佛
echo  =========================================================================
echo 正在检查您的系统是否安装过%AppName%
Wmic Process Get ExecutablePath | Findstr /i "%AppName%.exe" >%AppName%Path.txt&&SET FindAlist=1||SET FindAlist=0
IF %FindAlist%==1 (
    for /f "delims=" %%o in (%AppName%Path.txt) do (
        SET AListPath=%%o
        call set "AListPath=%%AListPath:!AppName!.exe=%%"
        call set "AListPath=%%AListPath: =%%"
    )
)  ELSE (
     ::沒有安裝過%AppName%
        echo 找了半天，正式确认您的系统没安装过%AppName%，现在开始帮您安装。
        echo  ===================请输入Alist的安装目录。例如D:\softapp===================
        echo 1、请注意不要填写C盘
        echo 2、请注意不要输入中文的目录。
        echo 3、请注意最好不要带空格的目录
        echo 4、特别注意：特别注意：特别注意，系统会自动在加Alist，例如您输入的是D:\soft,那么最终的安装目录就是d:\soft\Alist，如果您想自定义的话，请在后面确认时，按N重新输入即可。
        echo  =========================================================================
        SET /p AlistPath=请输入：
        set "AlistPath=!AlistPath!\"
        set "AlistPath=!AlistPath:/=\!"
        set "AlistPath=!AlistPath:\\=\!"
        set "AlistPath=!AlistPath: =!"
        echo 请确认您设置的安裝目錄：「%AlistPath%」，是否正确！&TIMEOUT /t 2 >NUL
        echo 请再次安裝目錄：「%AlistPath%」，是否正确！&TIMEOUT /t 2 >NUL
        echo 最后一次确认安裝目錄：「%AlistPath%」，是否正确！&TIMEOUT /t 2 >NUL
        set /p vars="确认请按：Y，重新输入请按：N"
        if %vars%==Y SET AppPath=!AlistPath!
        if %vars%==N SET /p AppPath=请重新输入：
        set "AppPath=%AppPath%\"
        set "AppPath=!AppPath:/=\!"
        set "AppPath=!AppPath:\\=\!"
        set "AppPath=!AppPath: =!"
        echo 您输入的安裝路径：「%AppPath%」
        rem echo !AlistPath!|Findstr /i /r "!AppName!">nul&&SET AppPath=!AlistPath!||SET AppPath=!AlistPath!!AppName!\
    )

 ::-------------------------------------
echo  ========================== 初始化中，請稍後 =========================

    IF NOT EXIST "%AppPath%tools" (md %AppPath%tools)
    cd /d %AppPath%

    ::判断是否为第一次安装
    IF EXIST %AppPath%!AppName!.exe (SET ISexist=1) ELSE (SET ISexist=0)
        ::判断文件是否存在
    WMIC Service GET name|Findstr /i "%ServiceName%" >nul&&SET ISservs=1||SET ISservs=0
    
    SET ISfirst=%ISexist%%ISservs%
      ::根据当前系统存在各种情况进行判断
    IF %ISfirst%==10 GOTO ReInstall
    IF %ISfirst%==00 GOTO Install
    IF %ISfirst%==01 GOTO RepairInstall
    IF %ISfirst%==11 GOTO Upgrade


:ReInstall
::10-重新安装：文件存在，但服务都不存在，需要重装。
    echo ============重新安装============
    ::调用环境初始化检查模块
    CALL :SetEnv

    ::调用服务安装模块
    CALL :Service

    ::调用Alist配置模块
    CALL :AlistWeb

    ::调用计划任务升级
    CALL :Taskschd

    goto End

:Install
::00-全新安装：文件和服务都不存在，需要全新安装。
    echo ============全新安装============

    ::调用环境初始化检查模块
    CALL :SetEnv

     ::调用下载和启动服务模块
    CALL :Down

     ::调用最新版本获取模块
    CALL :Latest

     ::调用服务安装模块
    CALL :Service

     ::调用Alist配置模块
    CALL :AlistWeb

    echo ::调用计划任务升级
    CALL :Taskschd

    goto End
    

:RepairInstall
::01-修复安装：文件不存在，但服务也安装过了，需要修复。
    echo ============修复安装============

    ::调用环境初始化检查模块
    CALL :SetEnv

    ::调用最新版本获取模块
    CALL :Latest

    ::调用下载和启动服务模块
    CALL :Down

    ::调用服务安装模块
    CALL :Service

    ::调用Alist配置模块
    CALL :AlistWeb

    goto End

:Upgrade
::11-升级安装：文件存在，服务也安装过了，需要升级。
    echo ============升级安装============

    ::调用环境初始化检查模块
    CALL :SetEnv

    ::调用最新版本获取模块
    CALL :Latest

    ::调用当前版本获取模块
    CALL :Current

    echo =====正在判断是否需要升级===
    if "%CurrentVersion%" == "%LatestVersion%" (echo %AppName%版本已经是最新的%LatestVersion%版，无需升级!) else (
      echo %AppName%的当前为%CurrentVersion%版，最新是%LatestVersion%，需要升级!
      nssm64 stop %ServiceName%>NUL 2>NUL
      echo %AppName%正在升级中，请稍等

      ::调用下载和启动服务模块
      CALL :Down
      TIMEOUT /t 2 >NUL

  )

    ::调用服务安装模块
    CALL :Service

      goto End

:SetEnv
    ::環境變量设置
    wmic ENVIRONMENT where "name='path' and username='<SYSTEM>'" set VariableValue='%path%;%AppPath%;%AppPath%tools;'>NUL 2>NUL
    ::复制相关组件并解压
    COPY %WINDIR%\JPEGView.ini %AppData%\JPEGView\ /y
    IF NOT EXIST "%AppPath%tools\AlistMan.exe" (
        COPY %temp%\AlistMan.exe %AppPath%\tools\ /y
        bz x -y -o:%AppPath%tools %AppPath%tools\AlistMan.exe
        bz x -y -o:%AppPath%tools %AppPath%tools\tools.exe
    )


    ::立即刷新环境变量生效，不用重启
    dllcall SendMessageTimeoutA,65535,26,,"Environment",2,4444,,user32

     ::安装RaiDrive 先判断系统是不事安装过了raidrive
    echo 正在檢查RaiDrive的安装情況
    WMIC Service  GET name|Findstr /i "%RaiD%" >nul&&echo RaiDrive 已经安装过了 ||SET RaiDriveIns=0 &TIMEOUT /t 2 >NUL
    IF %RaiDriveIns% =="0" (
    echo  您的系统还没有安装RaiDrive  过
    echo  请选择RaiDrive的安装版本：
    echo. 1、最新版（默认有广告），后面会自动屏蔽广告。
    echo. 2、旧版本（原生无广告），版本有点低但不影响。   
    echo  =========================================================================
    set /p choice=请选择RaiDrive的版本：
    if %choice%==1 choco install raidrive
    if %choice%==2 choco install raidrive --version=2020.11.38 -y
    )

  goto :EOF


:Service
    ::获取服务的安装状态，判断服务是否存在
    echo 正在检查Alist开机自启服务安装状态。
    WMIC Service  GET name|Findstr /i "%ServiceName%" >nul&&echo %ServiceName% 已经安装过了 ||echo 没有安装，正在安装Alist开机自启&&nssm64 install %ServiceName% %AppPath%%AppName%.exe server&TIMEOUT /t 2 >NUL
    nssm64 restart %ServiceName%>NUL 2>NUL&TIMEOUT /t 2 >NUL
    nircmd service restart %RaiD%>NUL 2>NUL&TIMEOUT /t 2 >NUL
    goto :EOF

:AlistWeb
    echo 恭喜成功，%AppName%的版本为&&%AppName% version | gawk64 -F": " "NR==5 {print $2}"
    rem !AppPath!!AppName!.exe admin&TIMEOUT /t 15 >NUL
    echo =====请设置好您的ALIST，然后按任意键继续===
    echo 恭喜恭喜，贺喜贺喜，Alist终于被您功能的征服了。>password.txt
    echo 下面是用户和密码，用于登录后台和设置RaiDrive>>password.txt
    echo --------------下面是用户名-------------->>password.txt
    echo admin>>password.txt
    echo --------------下面是密码-------------->>password.txt
    php-mini.exe -r "print_r (exec('cd /d d:\softapp\alist\&&alist.exe admin 2>&1', $res));"| gawk64 -F": " "{print $2}">>password.txt
    start notepad password.txt
        echo 开始打开ALIST界面
    start http://localhost:5244/
    TIMEOUT /t 15 >nul
    call jpegview !AppPath!tools\RaiDrive.png
    goto :EOF

:Latest
    ::获取云上最新版本
    Curl --ssl-no-revoke -sL !ReleasesUrl! | jq64 -r ".[0].name" >LatestVersion.txt
     ::设置最新版本信息为变量LatestVersion
    for /f "delims=" %%a in (LatestVersion.txt) do SET LatestVersion=%%a
    goto :EOF

:Current
     ::获取本地版本信息
    %AppPath%%AppName%.exe version | gawk64 -F": " "NR==5 {print $2}" >CurrentVersion.txt
     ::设置版本信息为变量CurrentVersion
    for /f "delims=" %%b in (CurrentVersion.txt) do SET CurrentVersion=%%b
    goto :EOF

:Down
    ::获取下载地址
    SET AppFile=amd64.zip
    Curl --ssl-no-revoke -sL !ReleasesUrl! | jq64 -r ".[0].assets[].name" | grep -e "amd64.zip">AppFile.txt
    for /f "delims=" %%p in (AppFile.txt) do SET AppFile=%%p
    Curl --ssl-no-revoke -sL !ReleasesUrl! | jq64 -r ".[0].assets[].browser_download_url" | grep -e "%AppFile%">down.txt
    for /f "delims=" %%d in (down.txt) do SET AppUrl=https://ghproxy.com/%%d

    ::下载安装
    echo 正在下载中......
    Curl --ssl-no-revoke -C - -O --output-dir %AppPath% !AppUrl!
    bz x -y -o:%AppPath% %AppFile%
    rem ECHO Y|unzip -o -d %AppPath% %AppFile% >NUL 2>NUL

    goto :EOF


:Taskschd
    echo 正在添加计划任务，自动更新Alist
    SET var=0
    ::读取任务计划中的%AppUp%任务,如果有就显示,如果没有就报错
    schtasks /query /tn %AppUp% |findstr /m "%AppUp%" >NUL 2>NUL&&SET var=1  
    ::检查上一条指令是否产生与ABC有关的信息,如果没有就执行X;如过有就执行Y
    if ERRORLEVEL 1 (schtasks /create /ru system /tn "%AppUp%" /tr %AppPath%%AppUp%.bat /ST 21:30 /sc weekly /mo 1 /d FRI&&echo 添加升级任务成功)else (echo 升级任务已经存在)
    TIMEOUT /t 2 >NUL
    net start %RaiD% >NUL 2>NUL
 
    goto :EOF

:End
::设置RaiDrive的启动方式设置为自动延迟启动，避免Alist还没启动。Raidrive先启动导致网盘重启后无法挂载的问题。
sc config "%RaiD%" start=delayed-auto >NUL 2>NUL

:获取RaiDrive进程的路径
Wmic Process Get ExecutablePath |Findstr "RaiDrive.exe" | sed64 "s/[[:space:]]*$//" |head -1 >RaiDrive.txt
for /f "delims=" %%r in (RaiDrive.txt) do set RaiDrivePath=%%r
FVerTest %RaiDrivePath%|gawk64 -F.  "{print $1}"|sed64 -e "s/\[//g">CRaiDrive.txt
for /f "delims=" %%h in (CRaiDrive.txt) do set CRaiDrive=%%h
choco search raidrive|gawk64 -F"raidrive " "NR==2 {print $2}"|gawk64 -F"." "{print $1}">NRaiDrive.txt
for /f "delims=" %%j in (NRaiDrive.txt) do set NRaiDrive=%%j

IF %NRaiDrive% GEQ %CRaiDrive% (
echo 检查到您系统安装的RaiDrive是最新版本，需要屏蔽广告
TIMEOUT /t 10 >nul
net start MpsSvc>NUL 2>NUL
sc config MpsSvc start=auto >NUL 2>NUL
Netsh Advfirewall Set Allprofiles State ON>NUL 2>NUL
Set BlockName=msedgewebview2

:获取msedgewebview2进程的路径
Wmic Process Get ExecutablePath |Findstr "%BlockName%.exe" | sed64 "s/[[:space:]]*$//" |head -1 >BlockPath.txt
for /f "delims=" %%f in (BlockPath.txt) do (
  Netsh Advfirewall Firewall show rule "%BlockName%">nul&&echo "已经屏蔽过RaiDrive的广告了，请放心使用吧！"||Netsh Advfirewall Firewall Add Rule Name="%BlockName%" Dir=out Action=block Program="%%f" Enable=yes>nul&&echo "已经成功屏蔽RaiDrive的广告，欢迎回到纯净美好的世界！"
  )


:關閉相應的服務
net stop RaiDrive.Service
echo 正在重启RaiDrive挂载服务
taskkill /f /im msedgewebview* >NUL 2>NUL
taskkill /f /im RaiDrive*>NUL 2>NUL
net start RaiDrive.Service

:重新運行RaiDrive
echo 正在重新運行RaiDrive
nircmd exec %RaiDrivePath% ) else (echo 检查到您系统安装的RaiDrive是旧版本，原生无广告)

::清理相关垃圾
DEL /s /q CurrentVersion.txt down.txt LatestVersion.txt BlockPath.txt RaiDrive.txt newsize.txt oldsize.txt %AppName%Path.txt AppFile.txt CRaiDrive.txt NRaiDrive.txt>NUL 2>NUL

:: 
IF NOT EXIST "%AppPath%卸载%AppName%.CMD"(
@echo off>%AppPath%卸载%AppName%.CMD
SETlocal enabledelayedexpansion>>%AppPath%卸载%AppName%.CMD
title Alist卸载管理器 V1.0 by Fireye
echo  ========================== Alist卸载管理器 V1.0 =========================>>%AppPath%卸载%AppName%.CMD
echo                        南無大願地藏王菩薩 地獄不空 誓不成佛
echo  =========================================================================>>%AppPath%卸载%AppName%.CMD
nssm64 stop %ServiceName%>>%AppPath%%AppName%卸载.CMD>>%AppPath%卸载%AppName%.CMD
nssm64 remove %ServiceName% confirm>>%AppPath%卸载%AppName%.CMD>>%AppPath%卸载%AppName%.CMD
&ECHO 完成 &TIMEOUT /t 10 >NUL&EXIT>>%AppPath%卸载%AppName%.CMD
)

::创建桌面快捷方式
nircmd shortcut "!AppPath!!AppName!PLUS.CMD" "~$folder.desktop$" "Alist更新">NUL 2>NUL
nircmd shortcut "!AppPath!!AppName!卸载.CMD" "~$folder.desktop$" "Alist卸载">NUL 2>NUL
nircmd urlshortcut "http://127.0.0.1:5244" "~$folder.desktop$" "Alist后台">NUL 2>NUL
nircmd shortcut "!AppPath!password.txt" "~$folder.desktop$" "Alist密碼">NUL 2>NUL
nircmd urlshortcut "https://alist.nn.ci/zh/guide/#what-s-this" "~$folder.desktop$" "Alist帮助文档">NUL 2>NUL

::CLS&ECHO.&
ECHO.&ECHO 完成 &TIMEOUT /t 10 >NUL&EXIT











