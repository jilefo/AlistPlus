@echo off
SETlocal enabledelayedexpansion
::请设置好自己的路径，建议D盘
SET AppPath=D:\SoftAPP\Alist\
SET ServiceName=AlistDriveService
SET AppName=alist
SET ReposName=alist-org
SET AppUp=AlistUpgrade
SET ReleasesUrl=https://api.github.com/repos/%ReposName%/%AppName%/releases
SET RaiD=RaiDrive.Service
cd /d %AppPath%
IF NOT EXIST "tools" (md %AppPath%tools)

 ::复制本脚本到安装目录
IF NOT EXIST %AppPath%%AppUp%.bat  (copy %cd%\%AppUp%.bat %AppPath%)


 ::判断是否为第一次安装
  ::判断服务是否存在
IF EXIST %AppPath%%AppName%.exe (SET ISexist=1) ELSE (SET ISexist=0)
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

    ::调用工具下载模块
    CALL :Tools

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

     ::调用工具下载模块
    CALL :Tools

     ::调用旧数据迁移模块
    CALL :Migration

     ::调用最新版本获取模块
    CALL :Latest

     ::调用下载和启动服务模块
    CALL :Down

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

    ::调用工具下载模块
    CALL :Tools

    ::调用下载和启动服务模块
    CALL :Down

    ::调用最新版本获取模块
    CALL :Latest

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

    ::调用工具下载模块
    CALL :Tools

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
    rem taskkill /f /im explorer.exe & start explorer.exe >NUL 2>NUL

    ::检查chocolatey
    IF NOT EXIST "%ALLUSERSPROFILE%\chocolatey" (
     @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    )

     ::安装RaiDrive 先判断系统是不事安装过了raidrive
     echo 正在安装RaiDrive网盘挂载工具
     WMIC Service  GET name|Findstr /i "%RaiD%" >nul&&echo RaiDrive is already installed ||choco install curl -y --version=2020.11.38 -f -y&TIMEOUT /t 2 >NUL

     ::判断有些系统没有安装curl
     wmic datafile where "drive='c:' and FileName='curl' and Extension='exe'"|findstr /i "curl" >NUL 2>NUL ||choco install curl -y

    goto :EOF

:Migration
    ::数据迁移
    echo ::检查是否已经安装过Alist，如果存在则获得Data目录迁移到新的目录
    echo 正在检查您的系统是否安装过%AppName%
    Wmic Process Get ExecutablePath | Findstr /i "%AppName%.exe" | sed64 "s/[[:space:]]*$//" | head -1 | chcase /LOWER | gawk64 -F"%AppName%.exe" "NR==1 {print $1}" >%AppName%Data.txt

IF EXIST "%AppName%Data.txt" (

    for /f "delims=" %%d in (%AppName%Data.txt) do (SET DataPath=%%d)
    IF EXIST "%DataPath%" (
        if "%DataPath%" == "ehco %AppPath% | chcase /LOWER" (
        echo 正检查您设置的%AppName%目录与原来的%AppName%安装路径是相同的，无需备份原来的%AppName%数据"
        ) else (
                 echo 正在统计数据文件的大小
                 IF EXIST "%AppPath%data\data.db" (
                    wc -c "%AppPath%data\data.db" | gawk64 -F" " "{print $1}">newsize.txt
                     for /f "delims=" %%n in (newsize.txt) do (SET newsize=%%n)
             )
                 IF EXIST "%DataPath%data\data.db" (
                    wc -c "%DataPath%data\data.db" | gawk64 -F" " "{print $1}">oldsize.txt
                    for /f "delims=" %%o in (oldsize.txt) do (SET oldsize=%%o)
             )
                 taskkill /f /im %AppName%*
                 if "%oldsize%" gtr "%newsize%" (
                    echo 正在迁移旧数据
                    XCOPY "%AppPath%data\" "%DataPath%data\" /e /h /y /c /r
                    )  else (echo 无需迁移)
               )
    ) else (
            echo %DataPath%不存在，您的系统没有安装过%AppName%
        )
)
    goto :EOF


:Tools
  ::下載各種組件到Alist的安裝目錄
  jq64 -h >null&& goto :EOF || SET "PATH=%PATH%;AppPath%;%AppPath%tools;"
  SET ToolList=nssm64;gawk64;head;nircmd64;nircmdc64;FVerTest;dllcall;1.6/jq64;6.00/unzip;3.0/grep;1.19.4/wget64;1.19.4/wget64;4.8/sed64;nircmdc64;chcase;zip;wc;printf;tr
  SET BatUrl=http://bcn.bathome.net/tool
  echo 正在判断系统组件........
  :LoopDown
  for /f "tokens=1* delims=;" %%a in ("!ToolList!") do (
      SET ToolName=%%a.exe
      if not exist "%cd%\!ToolName!" (Curl --ssl-no-revoke -C - --create-dirs -O --output-dir tools %BatUrl%/!ToolName! >NUL 2>NUL)
      SET ToolList=%%b
  )

  if defined ToolList goto :LoopDown
  echo ::立即刷新环境变量生效，不用重启
  dllcall SendMessageTimeoutA,65535,26,,"Environment",2,4444,,user32

  goto :EOF


:Service
    ::获取服务的安装状态，判断服务是否存在

    WMIC Service  GET name|Findstr /i "%ServiceName%" >nul&&echo %ServiceName% is already installed ||nssm64 install %ServiceName% %AppPath%%AppName%.exe server&TIMEOUT /t 2 >NUL
    nssm64 restart %ServiceName%>NUL 2>NUL&TIMEOUT /t 2 >NUL
    nircmd service restart %RaiD%>NUL 2>NUL&TIMEOUT /t 2 >NUL
     
    goto :EOF

:AlistWeb
    echo 恭喜成功，%AppName%的版本为&&%AppName% version | gawk64 -F": " "NR==5 {print $2}"
    echo =====您现在的账号密码如下，记得复制下来===
    %AppPath%%AppName%.exe admin&TIMEOUT /t 15 >NUL
    echo 开始打开ALIST界面
    start http://localhost:5244/@login
    echo =====请设置好您的ALIST，然后按任意键继续===
    pause
    goto :EOF

:Latest
    ::获取云上最新版本
    Curl --ssl-no-revoke -sL !ReleasesUrl! | jq64 -r ".[0].name" >LatestVersion.txt
     ::设置最新版本信息为变量LatestVersion
    for /f "delims=" %%a in (LatestVersion.txt) do (
      SET LatestVersion=%%a
    )
     
    goto :EOF

:Current
     ::获取本地版本信息
    %AppPath%%AppName%.exe version | gawk64 -F": " "NR==5 {print $2}" >CurrentVersion.txt
     ::设置版本信息为变量CurrentVersion
    for /f "delims=" %%b in (CurrentVersion.txt) do (
      SET CurrentVersion=%%b
    )
     
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
    ECHO Y|unzip -o -d %AppPath% %AppFile% >NUL 2>NUL
     
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
sc config "%RaiD%" start=delayed-auto




:获取RaiDrive进程的路径
Wmic Process Get ExecutablePath |Findstr "RaiDrive.exe" | sed64 "s/[[:space:]]*$//" |head -1 >RaiDrive.txt
for /f "delims=" %%r in (RaiDrive.txt) do set RaiDrivePath=%%r
FVerTest %RaiDrivePath%|gawk64 -F.  "{print $1}"|sed64 -e "s/\[//g">CRaiDrive.txt
for /f "delims=" %%h in (CRaiDrive.txt) do set CRaiDrive=%%h
choco search raidrive|gawk64 -F"raidrive " "NR==2 {print $2}"|gawk64 -F"." "{print $1}">NRaiDrive.txt
for /f "delims=" %%j in (NRaiDrive.txt) do set NRaiDrive=%%j

IF %NRaiDrive% GEQ %CRaiDrive% (
echo 检查到您系统安装的RaiDrive是最新版本，需要屏蔽广告
choice /t 3 /d y /n >nul
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
nircmd64 exec %RaiDrivePath% ) else (echo 检查到您系统安装的RaiDrive是旧版本，原生无广告)

::开启防火墙
DEL /s /q CurrentVersion.txt down.txt LatestVersion.txt BlockPath.txt RaiDrive.txt newsize.txt oldsize.txt %AppName%Data.txt AppFile.txt CRaiDrive.txt NRaiDrive.txt>NUL 2>NUL
::CLS&ECHO.&
ECHO 完成! &TIMEOUT /t 10 >NUL
