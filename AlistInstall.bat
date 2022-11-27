@echo off
SETlocal enabledelayedexpansion
title Alist安裝管理器 V1.0 by Fireye
echo  ========================== Alist安裝管理器 V1.0 =========================
echo                        南無大願地藏王菩薩 地獄不空 誓不成佛
echo  =========================================================================

    ::環境變量设置
    wmic ENVIRONMENT where "name='path' and username='<SYSTEM>'" set VariableValue='%path%;%AppPath%;%AppPath%tools;'>NUL 2>NUL
    rem taskkill /f /im explorer.exe & start explorer.exe >NUL 2>NUL

    echo 正在检查chocolatey是否已经安装

     powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" 
    SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"




  