@echo off
SETlocal enabledelayedexpansion
title Alist安裝管理器 V1.0 by Fireye
SET ServiceName=AlistDriveService
SET AppName=alist
SET ReposName=alist-org
SET AppUp=Alist安裝
SET ReleasesUrl=https://api.github.com/repos/%ReposName%/%AppName%/releases
SET RaiD=RaiDrive.Service
SET RunPath=%cd%
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
        echo  =========================================================================
        SET /p AlistPath=请输入：
        pause
        set "AlistPath=!AlistPath!\"
        set "AlistPath=!AlistPath:/=\!"
        set "AlistPath=!AlistPath:\\=\!"
        set "AlistPath=!AlistPath: =!"
    )

 ::-------------------------------------
echo  ========================== 初始化中，請稍後 =========================
 echo !AlistPath!|Findstr /i /r "!AppName!">nul&&SET AppPath=!AlistPath!||set AppPath=!AlistPath!!AppName!\
 echo 安裝目錄：「!AppPath!」
    IF NOT EXIST "!AppPath!tools" (md !AppPath!tools)
    cd /d !AppPath!


    ::判断是否为第一次安装
        ::判断服务是否存在
    IF EXIST !AppPath!!AppName!.exe (SET ISexist=1) ELSE (SET ISexist=0)
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

       ::调用下载和启动服务模块
    CALL :Down

       ::调用最新版本获取模块
    CALL :Latest

       ::调用服务安装模块
    CALL :Service

       ::调用Alist配置模块
    CALL :AlistWeb

    echo   ::调用计划任务升级
    CALL :Taskschd

    goto End
    

:RepairInstall
  ::01-修复安装：文件不存在，但服务也安装过了，需要修复。
    echo ============修复安装============

      ::调用环境初始化检查模块
    CALL :SetEnv

      ::调用工具下载模块
    CALL :Tools

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
    wmic ENVIRONMENT where "name='path' and username='<SYSTEM>'" set VariableValue='%path%;!AppPath!;!AppPath!tools;'>NUL 2>NUL

      ::检查chocolatey
    IF NOT EXIST "%ALLUSERSPROFILE%\chocolatey" (
     @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]  ::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    )

       ::安装RaiDrive 先判断系统是不事安装过了raidrive
     echo 正在檢查RaiDrive的安装情況
     WMIC Service  GET name|Findstr /i "%RaiD%"&&SET RaiDriveIns=1||SET RaiDriveIns=0
     IF %RaiDriveIns%==0 (
         cls
         echo RaiDrive还没安装，現在開始安裝
         echo  ========================== Alist安裝管理器 V1.0 =========================
         echo                        南無大願地藏王菩薩 地獄不空 誓不成佛
         echo  =========================================================================
         echo  请选择RaiDrive的安装版本：
         echo. 1、最新版本（默认有广告可去广告）  
         echo. 2、旧版本（原生无广告）     
         echo  =========================================================================
         set /p choice=请选择RaiDrive的版本：
         if "%choice%"=="1" set RaiDriveVersion=" "
         if "%choice%"=="2" set RaiDriveVersion=--version=2020.11.38
         choco install RaiDrive -y %RaiDriveVersion% -f -y
     ) else (echo RaiDrive已经安装过了)

       ::判断有些系统没有安装curl
     wmic datafile where "drive='c:' and FileName='curl' and Extension='exe'"|findstr /i "curl" >NUL 2>NUL ||choco install curl -y

goto :EOF

:Migration
      ::数据迁移
      ::检查是否已经安装过Alist，如果存在则获得Data目录迁移到新的目录

IF EXIST "%AppName%Path.txt" (
    for /f "delims=" %%d in (%AppName%Path.txt) do (SET DataPath=%%d)
    IF EXIST "%DataPath%" (
        if "%DataPath%" == "echo !AppPath! | chcase /LOWER" (
        echo 正检查您设置的%AppName%目录与原来的%AppName%安装路径是相同的，无需备份原来的%AppName%数据"
        ) else (
                 echo 正在统计数据文件的大小
                 IF EXIST "!AppPath!data\data.db" (
                    wc -c "!AppPath!data\data.db" | gawk64 -F" " "{print $1}">newsize.txt
                     for /f "delims=" %%n in (newsize.txt) do (SET newsize=%%n)
             )
                 IF EXIST "%DataPath%data\data.db" (
                    wc -c "%DataPath%data\data.db" | gawk64 -F" " "{print $1}">oldsize.txt
                    for /f "delims=" %%o in (oldsize.txt) do (SET oldsize=%%o)
             )
                 taskkill /f /im %AppName%*
                 if "%oldsize%" gtr "%newsize%" (
                    echo 正在迁移旧数据
                    XCOPY "!AppPath!data\" "%DataPath%data\" /e /h /y /c /r
                    )  else (echo 无需迁移)
               )
    ) else (
            echo %DataPath%不存在，您的系统没有安装过%AppName%
        )
)

goto :EOF


:Tools
  ::下載各種組件到Alist的安裝目錄
  rem jq64 -h >null&& goto :EOF || SET "PATH=%PATH%;!AppPath!;!AppPath!tools;"
  SET "PATH=%PATH%;!AppPath!;!AppPath!tools;"
  SET ToolList=nssm64;gawk64;head;nircmd64;nircmdc64;FVerTest;dllcall;1.6/jq64;6.00/unzip;3.0/grep;1.19.4/wget64;1.19.4/wget64;4.8/sed64;nircmdc64;chcase;zip;wc;printf;tr;unrar;rar
  SET BatUrl=http://bcn.bathome.net/tool
  echo 正在判断系统组件........
  
  :LoopDown
  for /f "tokens=1* delims=;" %%a in ("!ToolList!") do (
      SET ToolName=%%a.exe
      if not exist "!AppPath!tools\!ToolName!" (Curl --ssl-no-revoke -C - --create-dirs -O --output-dir tools %BatUrl%/!ToolName! >NUL 2>NUL&TIMEOUT /t 2 >NUL)
      SET ToolList=%%b
  )
  if defined ToolList goto :LoopDown

    ::下载php迷你工具
  if not exist "!AppPath!tools\php-mini.exe" (Curl --ssl-no-revoke -C - --create-dirs -O --output-dir tools %BatUrl%/php-mini.rar >NUL 2>NUL&TIMEOUT /t 2 >NUL)
  unrar e -y !AppPath!tools\php-mini.rar -o- !AppPath!tools>NUL 2>NUL

    ::下载并配置看图小工具
  Curl --ssl-no-revoke -C - --create-dirs -O --output-dir tools https://ghproxy.com/https://github.com/sylikc/jpegview/releases/download/v1.0.40/JPEGView_1.0.40.zip >NUL 2>NUL
  unzip -o -d !AppPath!tools !AppPath!tools\JPEGView_1.0.40.zip >NUL 2>NUL
  move !AppPath!tools\JPEGView64\* !AppPath!tools >NUL 2>NUL
  md %appdata%\JPEGView >NUL 2>NUL
  COPY !AppPath!tools\JPEGView.ini %AppData%\JPEGView\ /y >NUL 2>NUL
  sed64 -i "116s/ShowFullScreen\=auto/ShowFullScreen\=false/g" %AppData%\JPEGView\JPEGView.ini >NUL 2>NUL

    ::立即刷新环境变量生效，不用重启
  dllcall SendMessageTimeoutA,65535,26,,"Environment",2,4444,,user32|Findstr /i "1">NUL 2>NUL&& echo 添加环境变量成功||echo 添加环境变量失败

goto :EOF


:Service
      ::获取服务的安装状态，判断服务是否存在
    echo 正在检查Alist是否安装为服务.....
    WMIC Service  GET name|Findstr /i "%ServiceName%" >nul&&echo %ServiceName% is already installed ||nssm64 install %ServiceName% !AppPath!!AppName!.exe server|Findstr /i "installed successfully">NUL 2>NUL&& echo %AppName%已經設置過自啟動||echo %AppName%還沒有設置自啟動
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
    curl --ssl-no-revoke --output-dir tools -o RaiDrive.png -e https://www.bilibili.com/read/cv19846436 https://attach.52pojie.cn/forum/202211/16/155234w4crvs40f5wp050f.jpg>NUL 2>NUL
    start jpegview !AppPath!tools\RaiDrive.png
    echo 请按任意键继续. . .
    pause
goto :EOF

:Latest
      ::获取云上最新版本
    Curl --ssl-no-revoke -sL !ReleasesUrl! | jq64 -r ".[0].name" >LatestVersion.txt
       ::设置最新版本信息为变量LatestVersion
    for /f "delims=" %%t in (LatestVersion.txt) do SET LatestVersion=%%t
     
goto :EOF

:Current
       ::获取本地版本信息
    !AppPath!!AppName!.exe version | gawk64 -F": " "NR==5 {print $2}" >CurrentVersion.txt
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
    Curl --ssl-no-revoke -C - -O --output-dir !AppPath! !AppUrl!
    ECHO Y|unzip -o -d !AppPath! %AppFile% >NUL 2>NUL
     
goto :EOF


:Taskschd
    echo 正在添加计划任务，自动更新Alist
    SET var=0
      ::读取任务计划中的%AppUp%任务,如果有就显示,如果没有就报错
    schtasks /query /tn %AppUp% |findstr /m "%AppUp%" >NUL 2>NUL&&SET var=1  
      ::检查上一条指令是否产生与ABC有关的信息,如果没有就执行X;如过有就执行Y
    if ERRORLEVEL 1 (schtasks /create /ru system /tn "%AppUp%" /tr !AppPath!%AppUp%.bat /ST 21:30 /sc weekly /mo 1 /d FRI >NUL 2>NUL&&echo 添加升级任务成功) else (echo 升级任务已经存在)
 
goto :EOF

:End
  ::设置RaiDrive的启动方式设置为自动延迟启动，避免Alist还没启动。Raidrive先启动导致网盘重启后无法挂载的问题。
sc config "%RaiD%" start=delayed-auto >NUL 2>NUL

 ::获取RaiDrive进程的路径
Wmic Process Get ExecutablePath |Findstr "RaiDrive.exe" | sed64 "s/[[:space:]]*$//" |head -1 >RaiDrive.txt
for /f "delims=" %%r in (RaiDrive.txt) do set RaiDrivePath=%%r
FVerTest %RaiDrivePath%|gawk64 -F.  "{print $1}"|sed64 -e "s/\[//g">CRaiDrive.txt
for /f "delims=" %%h in (CRaiDrive.txt) do set CRaiDrive=%%h
choco search raidrive|gawk64 -F"raidrive " "NR==2 {print $2}"|gawk64 -F"." "{print $1}">NRaiDrive.txt
for /f "delims=" %%j in (NRaiDrive.txt) do set NRaiDrive=%%j

IF %NRaiDrive% GEQ %CRaiDrive% (
echo 检查到您系统安装的RaiDrive是最新版本
TIMEOUT /t 10 >nul
net start MpsSvc>NUL 2>NUL
sc config MpsSvc start=auto >NUL 2>NUL
Netsh Advfirewall Set Allprofiles State ON>NUL 2>NUL
Set BlockName=msedgewebview2
echo 正在检查是否需要屏蔽RaiDrive广告
 ::获取msedgewebview2进程的路径

Wmic Process Get ExecutablePath |Findstr "%BlockName%.exe" | sed64 "s/[[:space:]]*$//" |head -1 >BlockPath.txt
for /f "delims=" %%f in (BlockPath.txt) do (
  Netsh Advfirewall Firewall show rule "%BlockName%">nul&&echo "已经屏蔽过RaiDrive的广告了，请放心使用吧！"||Netsh Advfirewall Firewall Add Rule Name="%BlockName%" Dir=out Action=block Program="%%f" Enable=yes>nul&&echo "已经成功屏蔽RaiDrive的广告，欢迎回到纯净美好的世界！"
  )


 ::關閉相應的服務
net stop RaiDrive.Service >NUL 2>NUL
echo 正在重启RaiDrive挂载服务
taskkill /f /im msedgewebview* >NUL 2>NUL
taskkill /f /im RaiDrive*>NUL 2>NUL
net start RaiDrive.Service>NUL 2>NUL

 ::重新運行RaiDrive
echo 正在重新運行RaiDrive
call %RaiDrivePath%>NUL 2>NUL

  :: 增加卸载文件
IF NOT EXIST "!AppPath!!AppName!卸载.CMD" (
echo @echo off>!AppPath!!AppName!卸载.CMD
echo SETlocal enabledelayedexpansion>>!AppPath!!AppName!卸载.CMD
echo echo title Alist卸载管理器 V1.0 by Fireye>>!AppPath!!AppName!卸载.CMD
echo echo  ========================== Alist卸载管理器 V1.0 =========================>>!AppPath!!AppName!卸载.CMD
echo echo                        南無大願地藏王菩薩 地獄不空 誓不成佛                  >>!AppPath!!AppName!卸载.CMD
echo echo  =========================================================================>>!AppPath!!AppName!卸载.CMD
echo echo 正在備份相關數據........
echo xcopy "!AppPath!Data\" "!AppPath!Backup\" /e /h /y /c /r >NUL 2>NUL>>!AppPath!!AppName!卸载.CMD
echo TIMEOUT /t 5 >NUL 2>NUL>>!AppPath!!AppName!卸载.CMD
echo echo 正在刪除相關文件........
echo nssm64 stop %ServiceName%>>!AppPath!!AppName!卸载.CMD
echo nssm64 remove %ServiceName% confirm>>!AppPath!!AppName!卸载.CMD
echo schtasks /delete /tn "%AppUp%" /f>>!AppPath!!AppName!卸载.CMD
echo schtasks /delete /tn "AlistUpgrade" /f>>!AppPath!!AppName!卸载.CMD
echo TIMEOUT /t 5 >NUL 2>NUL>>!AppPath!!AppName!卸载.CMD
echo &ECHO 卸载完成 &TIMEOUT /t 10 >NUL&EXIT>>!AppPath!!AppName!卸载.CMD
)

  ::创建桌面快捷方式
nircmdc64 shortcut "!AppPath!!AppName!安裝.CMD" "~$folder.desktop$" "Alist安裝">NUL 2>NUL
nircmdc64 shortcut "!AppPath!!AppName!卸载.CMD" "~$folder.desktop$" "Alist安裝卸载">NUL 2>NUL
nircmdc64 urlshortcut "http://127.0.0.1:5244" "~$folder.desktop$" "Alist后台">NUL 2>NUL

 ::自动清静之前的VBS启动试
echo 自動清理之前設置過ALIST開機，刪除之前先進行備份....
set Startup=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\
md !AppPath!Backup>NUL 2>NUL
xcopy "%Startup%" "!AppPath!Backup\" /e /h /y /c /r >NUL 2>NUL
rem del /s /q %Startup%*.bat %Startup%*.vbs %Startup%*.cmd %Startup%*.lnk
  ::清理相关垃圾
DEL /s /q CurrentVersion.txt down.txt LatestVersion.txt BlockPath.txt RaiDrive.txt newsize.txt oldsize.txt %AppName%Path.txt AppFile.txt CRaiDrive.txt NRaiDrive.txt>NUL 2>NUL
pause
   ::复制本脚本到安装目录
IF "echo !AppPath! | chcase /LOWER | head -1" NEQ "echo %RunPath%\ | chcase /LOWER | head -1" (
  echo IF NOT EXIST "!AppPath!%AppUp%.CMD" copy %RunPath%\%AppUp%.CMD !AppPath! /y>%RunPath%\copycmd.bat
  call %RunPath%\copycmd.bat
)

ECHO.&ECHO 完成 &TIMEOUT /t 10 >NUL&EXIT