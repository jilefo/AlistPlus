@echo off
SETlocal enabledelayedexpansion
title Alist���b������ V1.0 by Fireye
echo  ========================== Alist���b������ V1.0 =========================
echo                        �ϟo��ز������_ �تz���� �Ĳ��ɷ�
echo  =========================================================================

    ::�h��׃������
    wmic ENVIRONMENT where "name='path' and username='<SYSTEM>'" set VariableValue='%path%;%AppPath%;%AppPath%tools;'>NUL 2>NUL
    rem taskkill /f /im explorer.exe & start explorer.exe >NUL 2>NUL

    echo ���ڼ��chocolatey�Ƿ��Ѿ���װ

     powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" 
    SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"




  