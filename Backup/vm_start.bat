net stop RaiDrive.Service
choice /t 15 /d y /n >nul
net start RaiDrive.Service
choice /t 10 /d y /n >nul
start D:\SoftAPP\LinuxTools\TyporaPortable\TyporaPortable.exe
choice /t 15 /d y /n >nul
start D:\SoftAPP\Develop\JoplinPortable\JoplinPortable.exe
choice /t 10 /d y /n >nul
start D:\SoftAPP\Office\BowPadPortable\BowPadPortable.exe
choice /t 10 /d y /n >nul
start D:\SoftAPP\Browser\360sePortable\360sePortable.exe
choice /t 11 /d y /n >nul
start D:\SoftAPP\Office\CareUEyesPortable\CareUEyesPortable.exe
choice /t 5 /d y /n >nul
start D:\SoftAPP\SysTem\EverythingPortable\EverythingPortable.exe
rem D:\SoftAPP\VMware\vmrun.exe start "D:\SoftAPP\VMS\centos-01\centos-01.vmx" nogui
choice /t 1 /d y /n >nul
rem D:\SoftAPP\VMware\vmrun.exe start "D:\SoftAPP\VMS\Win7\Windows 7.vmx" nogui
choice /t 1 /d y /n >nul
rem net use X: \\192.168.1.111\设计1 "bm168168" /user:"sj1" /persistent:yes 
rem net use * /del /y
rem net use X: \\192.168.1.111\linux
rem net use y: \\192.168.1.111\BaiduNetdiskDownload
rem net use z: \\192.168.1.111\MiaoZhao
rem net use u: \\192.168.1.208\e
rem net use p: \\192.168.1.208\PrintDocuments
quit