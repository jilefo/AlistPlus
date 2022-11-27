@echo off
SETlocal enabledelayedexpansion
::�����ú��Լ���·��������D��
SET AppPath=D:\SoftAPP\Alist\
SET ServiceName=AlistDriveService
SET AppName=alist
SET ReposName=alist-org
SET AppUp=AlistUpgrade
SET ReleasesUrl=https://api.github.com/repos/%ReposName%/%AppName%/releases
SET RaiD=RaiDrive.Service
cd /d %AppPath%
IF NOT EXIST "tools" (md %AppPath%tools)

 ::���Ʊ��ű�����װĿ¼
IF NOT EXIST %AppPath%%AppUp%.bat  (copy %cd%\%AppUp%.bat %AppPath%)


 ::�ж��Ƿ�Ϊ��һ�ΰ�װ
  ::�жϷ����Ƿ����
IF EXIST %AppPath%%AppName%.exe (SET ISexist=1) ELSE (SET ISexist=0)
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

     ::�������°汾��ȡģ��
    CALL :Latest

     ::�������غ���������ģ��
    CALL :Down

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

    ::���ù�������ģ��
    CALL :Tools

    ::�������غ���������ģ��
    CALL :Down

    ::�������°汾��ȡģ��
    CALL :Latest

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
    wmic ENVIRONMENT where "name='path' and username='<SYSTEM>'" set VariableValue='%path%;%AppPath%;%AppPath%tools;'>NUL 2>NUL
    rem taskkill /f /im explorer.exe & start explorer.exe >NUL 2>NUL

    ::���chocolatey
    IF NOT EXIST "%ALLUSERSPROFILE%\chocolatey" (
     @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    )

     ::��װRaiDrive ���ж�ϵͳ�ǲ��°�װ����raidrive
     echo ���ڰ�װRaiDrive���̹��ع���
     WMIC Service  GET name|Findstr /i "%RaiD%" >nul&&echo RaiDrive is already installed ||choco install curl -y --version=2020.11.38 -f -y&TIMEOUT /t 2 >NUL

     ::�ж���Щϵͳû�а�װcurl
     wmic datafile where "drive='c:' and FileName='curl' and Extension='exe'"|findstr /i "curl" >NUL 2>NUL ||choco install curl -y

    goto :EOF

:Migration
    ::����Ǩ��
    echo ::����Ƿ��Ѿ���װ��Alist�������������DataĿ¼Ǩ�Ƶ��µ�Ŀ¼
    echo ���ڼ������ϵͳ�Ƿ�װ��%AppName%
    Wmic Process Get ExecutablePath | Findstr /i "%AppName%.exe" | sed64 "s/[[:space:]]*$//" | head -1 | chcase /LOWER | gawk64 -F"%AppName%.exe" "NR==1 {print $1}" >%AppName%Data.txt

IF EXIST "%AppName%Data.txt" (

    for /f "delims=" %%d in (%AppName%Data.txt) do (SET DataPath=%%d)
    IF EXIST "%DataPath%" (
        if "%DataPath%" == "ehco %AppPath% | chcase /LOWER" (
        echo ����������õ�%AppName%Ŀ¼��ԭ����%AppName%��װ·������ͬ�ģ����豸��ԭ����%AppName%����"
        ) else (
                 echo ����ͳ�������ļ��Ĵ�С
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
                    echo ����Ǩ�ƾ�����
                    XCOPY "%AppPath%data\" "%DataPath%data\" /e /h /y /c /r
                    )  else (echo ����Ǩ��)
               )
    ) else (
            echo %DataPath%�����ڣ�����ϵͳû�а�װ��%AppName%
        )
)
    goto :EOF


:Tools
  ::���d���N�M����Alist�İ��bĿ�
  jq64 -h >null&& goto :EOF || SET "PATH=%PATH%;AppPath%;%AppPath%tools;"
  SET ToolList=nssm64;gawk64;head;nircmd64;nircmdc64;FVerTest;dllcall;1.6/jq64;6.00/unzip;3.0/grep;1.19.4/wget64;1.19.4/wget64;4.8/sed64;nircmdc64;chcase;zip;wc;printf;tr
  SET BatUrl=http://bcn.bathome.net/tool
  echo �����ж�ϵͳ���........
  :LoopDown
  for /f "tokens=1* delims=;" %%a in ("!ToolList!") do (
      SET ToolName=%%a.exe
      if not exist "%cd%\!ToolName!" (Curl --ssl-no-revoke -C - --create-dirs -O --output-dir tools %BatUrl%/!ToolName! >NUL 2>NUL)
      SET ToolList=%%b
  )

  if defined ToolList goto :LoopDown
  echo ::����ˢ�»���������Ч����������
  dllcall SendMessageTimeoutA,65535,26,,"Environment",2,4444,,user32

  goto :EOF


:Service
    ::��ȡ����İ�װ״̬���жϷ����Ƿ����

    WMIC Service  GET name|Findstr /i "%ServiceName%" >nul&&echo %ServiceName% is already installed ||nssm64 install %ServiceName% %AppPath%%AppName%.exe server&TIMEOUT /t 2 >NUL
    nssm64 restart %ServiceName%>NUL 2>NUL&TIMEOUT /t 2 >NUL
    nircmd service restart %RaiD%>NUL 2>NUL&TIMEOUT /t 2 >NUL
     
    goto :EOF

:AlistWeb
    echo ��ϲ�ɹ���%AppName%�İ汾Ϊ&&%AppName% version | gawk64 -F": " "NR==5 {print $2}"
    echo =====�����ڵ��˺��������£��ǵø�������===
    %AppPath%%AppName%.exe admin&TIMEOUT /t 15 >NUL
    echo ��ʼ��ALIST����
    start http://localhost:5244/@login
    echo =====�����ú�����ALIST��Ȼ�����������===
    pause
    goto :EOF

:Latest
    ::��ȡ�������°汾
    Curl --ssl-no-revoke -sL !ReleasesUrl! | jq64 -r ".[0].name" >LatestVersion.txt
     ::�������°汾��ϢΪ����LatestVersion
    for /f "delims=" %%a in (LatestVersion.txt) do (
      SET LatestVersion=%%a
    )
     
    goto :EOF

:Current
     ::��ȡ���ذ汾��Ϣ
    %AppPath%%AppName%.exe version | gawk64 -F": " "NR==5 {print $2}" >CurrentVersion.txt
     ::���ð汾��ϢΪ����CurrentVersion
    for /f "delims=" %%b in (CurrentVersion.txt) do (
      SET CurrentVersion=%%b
    )
     
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
    ECHO Y|unzip -o -d %AppPath% %AppFile% >NUL 2>NUL
     
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
sc config "%RaiD%" start=delayed-auto




:��ȡRaiDrive���̵�·��
Wmic Process Get ExecutablePath |Findstr "RaiDrive.exe" | sed64 "s/[[:space:]]*$//" |head -1 >RaiDrive.txt
for /f "delims=" %%r in (RaiDrive.txt) do set RaiDrivePath=%%r
FVerTest %RaiDrivePath%|gawk64 -F.  "{print $1}"|sed64 -e "s/\[//g">CRaiDrive.txt
for /f "delims=" %%h in (CRaiDrive.txt) do set CRaiDrive=%%h
choco search raidrive|gawk64 -F"raidrive " "NR==2 {print $2}"|gawk64 -F"." "{print $1}">NRaiDrive.txt
for /f "delims=" %%j in (NRaiDrive.txt) do set NRaiDrive=%%j

IF %NRaiDrive% GEQ %CRaiDrive% (
echo ��鵽��ϵͳ��װ��RaiDrive�����°汾����Ҫ���ι��
choice /t 3 /d y /n >nul
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
nircmd64 exec %RaiDrivePath% ) else (echo ��鵽��ϵͳ��װ��RaiDrive�Ǿɰ汾��ԭ���޹��)

::��������ǽ
DEL /s /q CurrentVersion.txt down.txt LatestVersion.txt BlockPath.txt RaiDrive.txt newsize.txt oldsize.txt %AppName%Data.txt AppFile.txt CRaiDrive.txt NRaiDrive.txt>NUL 2>NUL
::CLS&ECHO.&
ECHO ���! &TIMEOUT /t 10 >NUL
