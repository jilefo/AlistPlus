@echo off
SETlocal enabledelayedexpansion
echo title Alist卸载管理器 V1.0 by Fireye
echo  ========================== Alist卸载管理器 V1.0 =========================
echo                        南無大願地藏王菩薩 地獄不空 誓不成佛                  
echo  =========================================================================
xcopy "D:\SoftAPP\Alist\Data\" "D:\SoftAPP\Alist\Backup\" /e /h /y /c /r 
TIMEOUT /t 5 
nssm64 stop AlistDriveService
nssm64 remove AlistDriveService confirm
schtasks /delete /tn "Alist安裝" /f
schtasks /delete /tn "AlistUpgrade" /f
TIMEOUT /t 5 
