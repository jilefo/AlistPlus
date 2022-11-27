@echo off
SETlocal enabledelayedexpansion
title Alist���b������ V1.0 by Fireye
SET ServiceName=AlistDriveService
SET AppName=alist
SET ReposName=alist-org
SET AppUp=Alist���b
SET ReleasesUrl=https://api.github.com/repos/%ReposName%/%AppName%/releases
SET RaiD=RaiDrive.Service
SET RunPath=%cd%
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
        echo  =========================================================================
        SET /p AlistPath=�����룺
        pause
        set "AlistPath=!AlistPath!\"
        set "AlistPath=!AlistPath:/=\!"
        set "AlistPath=!AlistPath:\\=\!"
        set "AlistPath=!AlistPath: =!"
    )

 ::-------------------------------------
echo  ========================== ��ʼ���У�Ո���� =========================
 echo !AlistPath!|Findstr /i /r "!AppName!">nul&&SET AppPath=!AlistPath!||set AppPath=!AlistPath!!AppName!\
 echo ���bĿ䛣���!AppPath!��
    IF NOT EXIST "!AppPath!tools" (md !AppPath!tools)
    cd /d !AppPath!


    ::�ж��Ƿ�Ϊ��һ�ΰ�װ
        ::�жϷ����Ƿ����
    IF EXIST !AppPath!!AppName!.exe (SET ISexist=1) ELSE (SET ISexist=0)
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

      ::���ù�������ģ��
    CALL :Tools

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

       ::���ù�������ģ��
    CALL :Tools

       ::���þ�����Ǩ��ģ��
    CALL :Migration

       ::�������غ���������ģ��
    CALL :Down

       ::�������°汾��ȡģ��
    CALL :Latest

       ::���÷���װģ��
    CALL :Service

       ::����Alist����ģ��
    CALL :AlistWeb

    echo   ::���üƻ���������
    CALL :Taskschd

    goto End
    

:RepairInstall
  ::01-�޸���װ���ļ������ڣ�������Ҳ��װ���ˣ���Ҫ�޸���
    echo ============�޸���װ============

      ::���û�����ʼ�����ģ��
    CALL :SetEnv

      ::���ù�������ģ��
    CALL :Tools

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

      ::���ù�������ģ��
    CALL :Tools

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
    wmic ENVIRONMENT where "name='path' and username='<SYSTEM>'" set VariableValue='%path%;!AppPath!;!AppPath!tools;'>NUL 2>NUL

      ::���chocolatey
    IF NOT EXIST "%ALLUSERSPROFILE%\chocolatey" (
     @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]  ::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    )

       ::��װRaiDrive ���ж�ϵͳ�ǲ��°�װ����raidrive
     echo ���ڙz��RaiDrive�İ�װ��r
     WMIC Service  GET name|Findstr /i "%RaiD%"&&SET RaiDriveIns=1||SET RaiDriveIns=0
     IF %RaiDriveIns%==0 (
         cls
         echo RaiDrive��û��װ���F���_ʼ���b
         echo  ========================== Alist���b������ V1.0 =========================
         echo                        �ϟo��ز������_ �تz���� �Ĳ��ɷ�
         echo  =========================================================================
         echo  ��ѡ��RaiDrive�İ�װ�汾��
         echo. 1�����°汾��Ĭ���й���ȥ��棩  
         echo. 2���ɰ汾��ԭ���޹�棩     
         echo  =========================================================================
         set /p choice=��ѡ��RaiDrive�İ汾��
         if "%choice%"=="1" set RaiDriveVersion=" "
         if "%choice%"=="2" set RaiDriveVersion=--version=2020.11.38
         choco install RaiDrive -y %RaiDriveVersion% -f -y
     ) else (echo RaiDrive�Ѿ���װ����)

       ::�ж���Щϵͳû�а�װcurl
     wmic datafile where "drive='c:' and FileName='curl' and Extension='exe'"|findstr /i "curl" >NUL 2>NUL ||choco install curl -y

goto :EOF

:Migration
      ::����Ǩ��
      ::����Ƿ��Ѿ���װ��Alist�������������DataĿ¼Ǩ�Ƶ��µ�Ŀ¼

IF EXIST "%AppName%Path.txt" (
    for /f "delims=" %%d in (%AppName%Path.txt) do (SET DataPath=%%d)
    IF EXIST "%DataPath%" (
        if "%DataPath%" == "echo !AppPath! | chcase /LOWER" (
        echo ����������õ�%AppName%Ŀ¼��ԭ����%AppName%��װ·������ͬ�ģ����豸��ԭ����%AppName%����"
        ) else (
                 echo ����ͳ�������ļ��Ĵ�С
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
                    echo ����Ǩ�ƾ�����
                    XCOPY "!AppPath!data\" "%DataPath%data\" /e /h /y /c /r
                    )  else (echo ����Ǩ��)
               )
    ) else (
            echo %DataPath%�����ڣ�����ϵͳû�а�װ��%AppName%
        )
)

goto :EOF


:Tools
  ::���d���N�M����Alist�İ��bĿ�
  rem jq64 -h >null&& goto :EOF || SET "PATH=%PATH%;!AppPath!;!AppPath!tools;"
  SET "PATH=%PATH%;!AppPath!;!AppPath!tools;"
  SET ToolList=nssm64;gawk64;head;nircmd64;nircmdc64;FVerTest;dllcall;1.6/jq64;6.00/unzip;3.0/grep;1.19.4/wget64;1.19.4/wget64;4.8/sed64;nircmdc64;chcase;zip;wc;printf;tr;unrar;rar
  SET BatUrl=http://bcn.bathome.net/tool
  echo �����ж�ϵͳ���........
  
  :LoopDown
  for /f "tokens=1* delims=;" %%a in ("!ToolList!") do (
      SET ToolName=%%a.exe
      if not exist "!AppPath!tools\!ToolName!" (Curl --ssl-no-revoke -C - --create-dirs -O --output-dir tools %BatUrl%/!ToolName! >NUL 2>NUL&TIMEOUT /t 2 >NUL)
      SET ToolList=%%b
  )
  if defined ToolList goto :LoopDown

    ::����php���㹤��
  if not exist "!AppPath!tools\php-mini.exe" (Curl --ssl-no-revoke -C - --create-dirs -O --output-dir tools %BatUrl%/php-mini.rar >NUL 2>NUL&TIMEOUT /t 2 >NUL)
  unrar e -y !AppPath!tools\php-mini.rar -o- !AppPath!tools>NUL 2>NUL

    ::���ز����ÿ�ͼС����
  Curl --ssl-no-revoke -C - --create-dirs -O --output-dir tools https://ghproxy.com/https://github.com/sylikc/jpegview/releases/download/v1.0.40/JPEGView_1.0.40.zip >NUL 2>NUL
  unzip -o -d !AppPath!tools !AppPath!tools\JPEGView_1.0.40.zip >NUL 2>NUL
  move !AppPath!tools\JPEGView64\* !AppPath!tools >NUL 2>NUL
  md %appdata%\JPEGView >NUL 2>NUL
  COPY !AppPath!tools\JPEGView.ini %AppData%\JPEGView\ /y >NUL 2>NUL
  sed64 -i "116s/ShowFullScreen\=auto/ShowFullScreen\=false/g" %AppData%\JPEGView\JPEGView.ini >NUL 2>NUL

    ::����ˢ�»���������Ч����������
  dllcall SendMessageTimeoutA,65535,26,,"Environment",2,4444,,user32|Findstr /i "1">NUL 2>NUL&& echo ��ӻ��������ɹ�||echo ��ӻ�������ʧ��

goto :EOF


:Service
      ::��ȡ����İ�װ״̬���жϷ����Ƿ����
    echo ���ڼ��Alist�Ƿ�װΪ����.....
    WMIC Service  GET name|Findstr /i "%ServiceName%" >nul&&echo %ServiceName% is already installed ||nssm64 install %ServiceName% !AppPath!!AppName!.exe server|Findstr /i "installed successfully">NUL 2>NUL&& echo %AppName%�ѽ��O���^�Ԇ���||echo %AppName%߀�]���O���Ԇ���
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
    curl --ssl-no-revoke --output-dir tools -o RaiDrive.png -e https://www.bilibili.com/read/cv19846436 https://attach.52pojie.cn/forum/202211/16/155234w4crvs40f5wp050f.jpg>NUL 2>NUL
    start jpegview !AppPath!tools\RaiDrive.png
    echo �밴���������. . .
    pause
goto :EOF

:Latest
      ::��ȡ�������°汾
    Curl --ssl-no-revoke -sL !ReleasesUrl! | jq64 -r ".[0].name" >LatestVersion.txt
       ::�������°汾��ϢΪ����LatestVersion
    for /f "delims=" %%t in (LatestVersion.txt) do SET LatestVersion=%%t
     
goto :EOF

:Current
       ::��ȡ���ذ汾��Ϣ
    !AppPath!!AppName!.exe version | gawk64 -F": " "NR==5 {print $2}" >CurrentVersion.txt
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
    Curl --ssl-no-revoke -C - -O --output-dir !AppPath! !AppUrl!
    ECHO Y|unzip -o -d !AppPath! %AppFile% >NUL 2>NUL
     
goto :EOF


:Taskschd
    echo ������Ӽƻ������Զ�����Alist
    SET var=0
      ::��ȡ����ƻ��е�%AppUp%����,����о���ʾ,���û�оͱ���
    schtasks /query /tn %AppUp% |findstr /m "%AppUp%" >NUL 2>NUL&&SET var=1  
      ::�����һ��ָ���Ƿ������ABC�йص���Ϣ,���û�о�ִ��X;����о�ִ��Y
    if ERRORLEVEL 1 (schtasks /create /ru system /tn "%AppUp%" /tr !AppPath!%AppUp%.bat /ST 21:30 /sc weekly /mo 1 /d FRI >NUL 2>NUL&&echo �����������ɹ�) else (echo ���������Ѿ�����)
 
goto :EOF

:End
  ::����RaiDrive��������ʽ����Ϊ�Զ��ӳ�����������Alist��û������Raidrive���������������������޷����ص����⡣
sc config "%RaiD%" start=delayed-auto >NUL 2>NUL

 ::��ȡRaiDrive���̵�·��
Wmic Process Get ExecutablePath |Findstr "RaiDrive.exe" | sed64 "s/[[:space:]]*$//" |head -1 >RaiDrive.txt
for /f "delims=" %%r in (RaiDrive.txt) do set RaiDrivePath=%%r
FVerTest %RaiDrivePath%|gawk64 -F.  "{print $1}"|sed64 -e "s/\[//g">CRaiDrive.txt
for /f "delims=" %%h in (CRaiDrive.txt) do set CRaiDrive=%%h
choco search raidrive|gawk64 -F"raidrive " "NR==2 {print $2}"|gawk64 -F"." "{print $1}">NRaiDrive.txt
for /f "delims=" %%j in (NRaiDrive.txt) do set NRaiDrive=%%j

IF %NRaiDrive% GEQ %CRaiDrive% (
echo ��鵽��ϵͳ��װ��RaiDrive�����°汾
TIMEOUT /t 10 >nul
net start MpsSvc>NUL 2>NUL
sc config MpsSvc start=auto >NUL 2>NUL
Netsh Advfirewall Set Allprofiles State ON>NUL 2>NUL
Set BlockName=msedgewebview2
echo ���ڼ���Ƿ���Ҫ����RaiDrive���
 ::��ȡmsedgewebview2���̵�·��

Wmic Process Get ExecutablePath |Findstr "%BlockName%.exe" | sed64 "s/[[:space:]]*$//" |head -1 >BlockPath.txt
for /f "delims=" %%f in (BlockPath.txt) do (
  Netsh Advfirewall Firewall show rule "%BlockName%">nul&&echo "�Ѿ����ι�RaiDrive�Ĺ���ˣ������ʹ�ðɣ�"||Netsh Advfirewall Firewall Add Rule Name="%BlockName%" Dir=out Action=block Program="%%f" Enable=yes>nul&&echo "�Ѿ��ɹ�����RaiDrive�Ĺ�棬��ӭ�ص��������õ����磡"
  )


 ::�P�]�����ķ���
net stop RaiDrive.Service >NUL 2>NUL
echo ��������RaiDrive���ط���
taskkill /f /im msedgewebview* >NUL 2>NUL
taskkill /f /im RaiDrive*>NUL 2>NUL
net start RaiDrive.Service>NUL 2>NUL

 ::�����\��RaiDrive
echo ���������\��RaiDrive
call %RaiDrivePath%>NUL 2>NUL

  :: ����ж���ļ�
IF NOT EXIST "!AppPath!!AppName!ж��.CMD" (
echo @echo off>!AppPath!!AppName!ж��.CMD
echo SETlocal enabledelayedexpansion>>!AppPath!!AppName!ж��.CMD
echo echo title Alistж�ع����� V1.0 by Fireye>>!AppPath!!AppName!ж��.CMD
echo echo  ========================== Alistж�ع����� V1.0 =========================>>!AppPath!!AppName!ж��.CMD
echo echo                        �ϟo��ز������_ �تz���� �Ĳ��ɷ�                  >>!AppPath!!AppName!ж��.CMD
echo echo  =========================================================================>>!AppPath!!AppName!ж��.CMD
echo echo ���ڂ�����P����........
echo xcopy "!AppPath!Data\" "!AppPath!Backup\" /e /h /y /c /r >NUL 2>NUL>>!AppPath!!AppName!ж��.CMD
echo TIMEOUT /t 5 >NUL 2>NUL>>!AppPath!!AppName!ж��.CMD
echo echo ���ڄh�����P�ļ�........
echo nssm64 stop %ServiceName%>>!AppPath!!AppName!ж��.CMD
echo nssm64 remove %ServiceName% confirm>>!AppPath!!AppName!ж��.CMD
echo schtasks /delete /tn "%AppUp%" /f>>!AppPath!!AppName!ж��.CMD
echo schtasks /delete /tn "AlistUpgrade" /f>>!AppPath!!AppName!ж��.CMD
echo TIMEOUT /t 5 >NUL 2>NUL>>!AppPath!!AppName!ж��.CMD
echo &ECHO ж����� &TIMEOUT /t 10 >NUL&EXIT>>!AppPath!!AppName!ж��.CMD
)

  ::���������ݷ�ʽ
nircmdc64 shortcut "!AppPath!!AppName!���b.CMD" "~$folder.desktop$" "Alist���b">NUL 2>NUL
nircmdc64 shortcut "!AppPath!!AppName!ж��.CMD" "~$folder.desktop$" "Alist���bж��">NUL 2>NUL
nircmdc64 urlshortcut "http://127.0.0.1:5244" "~$folder.desktop$" "Alist��̨">NUL 2>NUL

 ::�Զ��徲֮ǰ��VBS������
echo �Ԅ�����֮ǰ�O���^ALIST�_�C���h��֮ǰ���M�Ђ��....
set Startup=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\
md !AppPath!Backup>NUL 2>NUL
xcopy "%Startup%" "!AppPath!Backup\" /e /h /y /c /r >NUL 2>NUL
rem del /s /q %Startup%*.bat %Startup%*.vbs %Startup%*.cmd %Startup%*.lnk
  ::�����������
DEL /s /q CurrentVersion.txt down.txt LatestVersion.txt BlockPath.txt RaiDrive.txt newsize.txt oldsize.txt %AppName%Path.txt AppFile.txt CRaiDrive.txt NRaiDrive.txt>NUL 2>NUL
pause
   ::���Ʊ��ű�����װĿ¼
IF "echo !AppPath! | chcase /LOWER | head -1" NEQ "echo %RunPath%\ | chcase /LOWER | head -1" (
  echo IF NOT EXIST "!AppPath!%AppUp%.CMD" copy %RunPath%\%AppUp%.CMD !AppPath! /y>%RunPath%\copycmd.bat
  call %RunPath%\copycmd.bat
)

ECHO.&ECHO ��� &TIMEOUT /t 10 >NUL&EXIT