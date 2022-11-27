@echo off
setlocal enabledelayedexpansion
set Alistpath=D:\SoftAPP\Alist
set ServiceName=AlistDriveService

cd /d %Alistpath%
nssm64 stop %ServiceName%
nssm64 remove %ServiceName% confirm
del /s /q  %ServiceName%\alist-windows-4.0-amd64.zip 