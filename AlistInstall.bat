@echo off
SETlocal enabledelayedexpansion
title Alist���b������ V1.0 by Fireye
echo  ========================== ʹ��˵��������ϸ����� =========================
echo                        �ϟo��ز������_ �تz���� �Ĳ��ɷ�
echo 1����ر�ɱ�������һ�������½ǣ��˳�ɱ�����
echo 2�����Ҽ�����-�Թ���Ա���������,���������ر���������
echo 3�����κ��������΢�ţ�858099909������Զ�̣�����ǰ��װ�����տ�Զ�̡�
echo  =========================================================================
pause
echo ��������ϵͳ����
:����UAC
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

:�������л���
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
echo  ========================== Alist���b������ V1.0 =========================
echo                        �ϟo��ز������_ �تz���� �Ĳ��ɷ�
echo  =========================================================================
echo ���ڼ������ϵͳ�Ƿ�װ��%AppName%
Wmic Process Get ExecutablePath | Findstr /i "%AppName%.exe" >%AppName%Path.txt&&SET FindAlist=1||SET FindAlist=0
IF %FindAlist%==1 (
    for /f "delims=" %%o in (%AppName%Path.txt) do (
        SET AListPath=%%o
        call set "AListPath=%%AListPath:!AppName!.exe=%%"
        call set "AListPath=%%AListPath: =%%"
    )
)  ELSE (
     ::�]�а��b�^%AppName%
        echo ���˰��죬��ʽȷ������ϵͳû��װ��%AppName%�����ڿ�ʼ������װ��
        echo  ===================������Alist�İ�װĿ¼������D:\softapp===================
        echo 1����ע�ⲻҪ��дC��
        echo 2����ע�ⲻҪ�������ĵ�Ŀ¼��
        echo 3����ע����ò�Ҫ���ո��Ŀ¼
        echo 4���ر�ע�⣺�ر�ע�⣺�ر�ע�⣬ϵͳ���Զ��ڼ�Alist���������������D:\soft,��ô���յİ�װĿ¼����d:\soft\Alist����������Զ���Ļ������ں���ȷ��ʱ����N�������뼴�ɡ�
        echo  =========================================================================
        SET /p AlistPath=�����룺
        set "AlistPath=!AlistPath!\"
        set "AlistPath=!AlistPath:/=\!"
        set "AlistPath=!AlistPath:\\=\!"
        set "AlistPath=!AlistPath: =!"
        echo ��ȷ�������õİ��bĿ䛣���%AlistPath%�����Ƿ���ȷ��&TIMEOUT /t 2 >NUL
        echo ���ٴΰ��bĿ䛣���%AlistPath%�����Ƿ���ȷ��&TIMEOUT /t 2 >NUL
        echo ���һ��ȷ�ϰ��bĿ䛣���%AlistPath%�����Ƿ���ȷ��&TIMEOUT /t 2 >NUL
        set /p vars="ȷ���밴��Y�����������밴��N"
        if %vars%==Y SET AppPath=!AlistPath!
        if %vars%==N SET /p AppPath=���������룺
        set "AppPath=%AppPath%\"
        set "AppPath=!AppPath:/=\!"
        set "AppPath=!AppPath:\\=\!"
        set "AppPath=!AppPath: =!"
        echo ������İ��b·������%AppPath%��
        rem echo !AlistPath!|Findstr /i /r "!AppName!">nul&&SET AppPath=!AlistPath!||SET AppPath=!AlistPath!!AppName!\
    )

 ::-------------------------------------
echo  ========================== ��ʼ���У�Ո���� =========================

    IF NOT EXIST "%AppPath%tools" (md %AppPath%tools)
    cd /d %AppPath%

    ::�ж��Ƿ�Ϊ��һ�ΰ�װ
    IF EXIST %AppPath%!AppName!.exe (SET ISexist=1) ELSE (SET ISexist=0)
        ::�ж��ļ��Ƿ����
    WMIC Service GET name|Findstr /i "%ServiceName%" >nul&&SET ISservs=1||SET ISservs=0
    
    SET ISfirst=%ISexist%%ISservs%
      ::���ݵ�ǰϵͳ���ڸ�����������ж�
    IF %ISfirst%==10 GOTO ReInstall
    IF %ISfirst%==00 GOTO Install
    IF %ISfirst%==01 GOTO RepairInstall
    IF %ISfirst%==11 GOTO Upgrade


:ReInstall
::10-���°�װ���ļ����ڣ������񶼲����ڣ���Ҫ��װ��
    echo ============���°�װ============
    ::���û�����ʼ�����ģ��
    CALL :SetEnv

    ::���÷���װģ��
    CALL :Service

    ::����Alist����ģ��
    CALL :AlistWeb

    ::���üƻ���������
    CALL :Taskschd

    goto End

:Install
::00-ȫ�°�װ���ļ��ͷ��񶼲����ڣ���Ҫȫ�°�װ��
    echo ============ȫ�°�װ============

    ::���û�����ʼ�����ģ��
    CALL :SetEnv

     ::�������غ���������ģ��
    CALL :Down

     ::�������°汾��ȡģ��
    CALL :Latest

     ::���÷���װģ��
    CALL :Service

     ::����Alist����ģ��
    CALL :AlistWeb

    echo ::���üƻ���������
    CALL :Taskschd

    goto End
    

:RepairInstall
::01-�޸���װ���ļ������ڣ�������Ҳ��װ���ˣ���Ҫ�޸���
    echo ============�޸���װ============

    ::���û�����ʼ�����ģ��
    CALL :SetEnv

    ::�������°汾��ȡģ��
    CALL :Latest

    ::�������غ���������ģ��
    CALL :Down

    ::���÷���װģ��
    CALL :Service

    ::����Alist����ģ��
    CALL :AlistWeb

    goto End

:Upgrade
::11-������װ���ļ����ڣ�����Ҳ��װ���ˣ���Ҫ������
    echo ============������װ============

    ::���û�����ʼ�����ģ��
    CALL :SetEnv

    ::�������°汾��ȡģ��
    CALL :Latest

    ::���õ�ǰ�汾��ȡģ��
    CALL :Current

    echo =====�����ж��Ƿ���Ҫ����===
    if "%CurrentVersion%" == "%LatestVersion%" (echo %AppName%�汾�Ѿ������µ�%LatestVersion%�棬��������!) else (
      echo %AppName%�ĵ�ǰΪ%CurrentVersion%�棬������%LatestVersion%����Ҫ����!
      nssm64 stop %ServiceName%>NUL 2>NUL
      echo %AppName%���������У����Ե�

      ::�������غ���������ģ��
      CALL :Down
      TIMEOUT /t 2 >NUL

  )

    ::���÷���װģ��
    CALL :Service

      goto End

:SetEnv
    ::�h��׃������
    wmic ENVIRONMENT where "name='path' and username='<SYSTEM>'" set VariableValue='%path%;%AppPath%;%AppPath%tools;'>NUL 2>NUL
    ::��������������ѹ
    COPY %WINDIR%\JPEGView.ini %AppData%\JPEGView\ /y
    IF NOT EXIST "%AppPath%tools\AlistMan.exe" (
        COPY %temp%\AlistMan.exe %AppPath%\tools\ /y
        bz x -y -o:%AppPath%tools %AppPath%tools\AlistMan.exe
        bz x -y -o:%AppPath%tools %AppPath%tools\tools.exe
    )


    ::����ˢ�»���������Ч����������
    dllcall SendMessageTimeoutA,65535,26,,"Environment",2,4444,,user32

     ::��װRaiDrive ���ж�ϵͳ�ǲ��°�װ����raidrive
    echo ���ڙz��RaiDrive�İ�װ��r
    WMIC Service  GET name|Findstr /i "%RaiD%" >nul&&echo RaiDrive �Ѿ���װ���� ||SET RaiDriveIns=0 &TIMEOUT /t 2 >NUL
    IF %RaiDriveIns% =="0" (
    echo  ����ϵͳ��û�а�װRaiDrive  ��
    echo  ��ѡ��RaiDrive�İ�װ�汾��
    echo. 1�����°棨Ĭ���й�棩��������Զ����ι�档
    echo. 2���ɰ汾��ԭ���޹�棩���汾�е�͵���Ӱ�졣   
    echo  =========================================================================
    set /p choice=��ѡ��RaiDrive�İ汾��
    if %choice%==1 choco install raidrive
    if %choice%==2 choco install raidrive --version=2020.11.38 -y
    )

  goto :EOF


:Service
    ::��ȡ����İ�װ״̬���жϷ����Ƿ����
    echo ���ڼ��Alist������������װ״̬��
    WMIC Service  GET name|Findstr /i "%ServiceName%" >nul&&echo %ServiceName% �Ѿ���װ���� ||echo û�а�װ�����ڰ�װAlist��������&&nssm64 install %ServiceName% %AppPath%%AppName%.exe server&TIMEOUT /t 2 >NUL
    nssm64 restart %ServiceName%>NUL 2>NUL&TIMEOUT /t 2 >NUL
    nircmd service restart %RaiD%>NUL 2>NUL&TIMEOUT /t 2 >NUL
    goto :EOF

:AlistWeb
    echo ��ϲ�ɹ���%AppName%�İ汾Ϊ&&%AppName% version | gawk64 -F": " "NR==5 {print $2}"
    rem !AppPath!!AppName!.exe admin&TIMEOUT /t 15 >NUL
    echo =====�����ú�����ALIST��Ȼ�����������===
    echo ��ϲ��ϲ����ϲ��ϲ��Alist���ڱ������ܵ������ˡ�>password.txt
    echo �������û������룬���ڵ�¼��̨������RaiDrive>>password.txt
    echo --------------�������û���-------------->>password.txt
    echo admin>>password.txt
    echo --------------����������-------------->>password.txt
    php-mini.exe -r "print_r (exec('cd /d d:\softapp\alist\&&alist.exe admin 2>&1', $res));"| gawk64 -F": " "{print $2}">>password.txt
    start notepad password.txt
        echo ��ʼ��ALIST����
    start http://localhost:5244/
    TIMEOUT /t 15 >nul
    call jpegview !AppPath!tools\RaiDrive.png
    goto :EOF

:Latest
    ::��ȡ�������°汾
    Curl --ssl-no-revoke -sL !ReleasesUrl! | jq64 -r ".[0].name" >LatestVersion.txt
     ::�������°汾��ϢΪ����LatestVersion
    for /f "delims=" %%a in (LatestVersion.txt) do SET LatestVersion=%%a
    goto :EOF

:Current
     ::��ȡ���ذ汾��Ϣ
    %AppPath%%AppName%.exe version | gawk64 -F": " "NR==5 {print $2}" >CurrentVersion.txt
     ::���ð汾��ϢΪ����CurrentVersion
    for /f "delims=" %%b in (CurrentVersion.txt) do SET CurrentVersion=%%b
    goto :EOF

:Down
    ::��ȡ���ص�ַ
    SET AppFile=amd64.zip
    Curl --ssl-no-revoke -sL !ReleasesUrl! | jq64 -r ".[0].assets[].name" | grep -e "amd64.zip">AppFile.txt
    for /f "delims=" %%p in (AppFile.txt) do SET AppFile=%%p
    Curl --ssl-no-revoke -sL !ReleasesUrl! | jq64 -r ".[0].assets[].browser_download_url" | grep -e "%AppFile%">down.txt
    for /f "delims=" %%d in (down.txt) do SET AppUrl=https://ghproxy.com/%%d

    ::���ذ�װ
    echo ����������......
    Curl --ssl-no-revoke -C - -O --output-dir %AppPath% !AppUrl!
    bz x -y -o:%AppPath% %AppFile%
    rem ECHO Y|unzip -o -d %AppPath% %AppFile% >NUL 2>NUL

    goto :EOF


:Taskschd
    echo ������Ӽƻ������Զ�����Alist
    SET var=0
    ::��ȡ����ƻ��е�%AppUp%����,����о���ʾ,���û�оͱ���
    schtasks /query /tn %AppUp% |findstr /m "%AppUp%" >NUL 2>NUL&&SET var=1  
    ::�����һ��ָ���Ƿ������ABC�йص���Ϣ,���û�о�ִ��X;����о�ִ��Y
    if ERRORLEVEL 1 (schtasks /create /ru system /tn "%AppUp%" /tr %AppPath%%AppUp%.bat /ST 21:30 /sc weekly /mo 1 /d FRI&&echo �����������ɹ�)else (echo ���������Ѿ�����)
    TIMEOUT /t 2 >NUL
    net start %RaiD% >NUL 2>NUL
 
    goto :EOF

:End
::����RaiDrive��������ʽ����Ϊ�Զ��ӳ�����������Alist��û������Raidrive���������������������޷����ص����⡣
sc config "%RaiD%" start=delayed-auto >NUL 2>NUL

:��ȡRaiDrive���̵�·��
Wmic Process Get ExecutablePath |Findstr "RaiDrive.exe" | sed64 "s/[[:space:]]*$//" |head -1 >RaiDrive.txt
for /f "delims=" %%r in (RaiDrive.txt) do set RaiDrivePath=%%r
FVerTest %RaiDrivePath%|gawk64 -F.  "{print $1}"|sed64 -e "s/\[//g">CRaiDrive.txt
for /f "delims=" %%h in (CRaiDrive.txt) do set CRaiDrive=%%h
choco search raidrive|gawk64 -F"raidrive " "NR==2 {print $2}"|gawk64 -F"." "{print $1}">NRaiDrive.txt
for /f "delims=" %%j in (NRaiDrive.txt) do set NRaiDrive=%%j

IF %NRaiDrive% GEQ %CRaiDrive% (
echo ��鵽��ϵͳ��װ��RaiDrive�����°汾����Ҫ���ι��
TIMEOUT /t 10 >nul
net start MpsSvc>NUL 2>NUL
sc config MpsSvc start=auto >NUL 2>NUL
Netsh Advfirewall Set Allprofiles State ON>NUL 2>NUL
Set BlockName=msedgewebview2

:��ȡmsedgewebview2���̵�·��
Wmic Process Get ExecutablePath |Findstr "%BlockName%.exe" | sed64 "s/[[:space:]]*$//" |head -1 >BlockPath.txt
for /f "delims=" %%f in (BlockPath.txt) do (
  Netsh Advfirewall Firewall show rule "%BlockName%">nul&&echo "�Ѿ����ι�RaiDrive�Ĺ���ˣ������ʹ�ðɣ�"||Netsh Advfirewall Firewall Add Rule Name="%BlockName%" Dir=out Action=block Program="%%f" Enable=yes>nul&&echo "�Ѿ��ɹ�����RaiDrive�Ĺ�棬��ӭ�ص��������õ����磡"
  )


:�P�]�����ķ���
net stop RaiDrive.Service
echo ��������RaiDrive���ط���
taskkill /f /im msedgewebview* >NUL 2>NUL
taskkill /f /im RaiDrive*>NUL 2>NUL
net start RaiDrive.Service

:�����\��RaiDrive
echo ���������\��RaiDrive
nircmd exec %RaiDrivePath% ) else (echo ��鵽��ϵͳ��װ��RaiDrive�Ǿɰ汾��ԭ���޹��)

::�����������
DEL /s /q CurrentVersion.txt down.txt LatestVersion.txt BlockPath.txt RaiDrive.txt newsize.txt oldsize.txt %AppName%Path.txt AppFile.txt CRaiDrive.txt NRaiDrive.txt>NUL 2>NUL

:: 
IF NOT EXIST "%AppPath%ж��%AppName%.CMD"(
@echo off>%AppPath%ж��%AppName%.CMD
SETlocal enabledelayedexpansion>>%AppPath%ж��%AppName%.CMD
title Alistж�ع����� V1.0 by Fireye
echo  ========================== Alistж�ع����� V1.0 =========================>>%AppPath%ж��%AppName%.CMD
echo                        �ϟo��ز������_ �تz���� �Ĳ��ɷ�
echo  =========================================================================>>%AppPath%ж��%AppName%.CMD
nssm64 stop %ServiceName%>>%AppPath%%AppName%ж��.CMD>>%AppPath%ж��%AppName%.CMD
nssm64 remove %ServiceName% confirm>>%AppPath%ж��%AppName%.CMD>>%AppPath%ж��%AppName%.CMD
&ECHO ��� &TIMEOUT /t 10 >NUL&EXIT>>%AppPath%ж��%AppName%.CMD
)

::���������ݷ�ʽ
nircmd shortcut "!AppPath!!AppName!PLUS.CMD" "~$folder.desktop$" "Alist����">NUL 2>NUL
nircmd shortcut "!AppPath!!AppName!ж��.CMD" "~$folder.desktop$" "Alistж��">NUL 2>NUL
nircmd urlshortcut "http://127.0.0.1:5244" "~$folder.desktop$" "Alist��̨">NUL 2>NUL
nircmd shortcut "!AppPath!password.txt" "~$folder.desktop$" "Alist�ܴa">NUL 2>NUL
nircmd urlshortcut "https://alist.nn.ci/zh/guide/#what-s-this" "~$folder.desktop$" "Alist�����ĵ�">NUL 2>NUL

::CLS&ECHO.&
ECHO.&ECHO ��� &TIMEOUT /t 10 >NUL&EXIT











