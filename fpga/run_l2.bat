@echo off
rem Laptop run L2 (about 1-1.5 hours). From the Vivado 2024.1 Tcl Shell:
rem     cd C:/Users/Anubhav/hush_fpga/fpga
rem     exec -ignorestderr cmd /c run_l2.bat
rem Progress and results: ..\out_l2\summary.txt
setlocal
set "OUT=%~dp0..\out_l2"
if not exist "%OUT%" mkdir "%OUT%"
echo run_l2 start %date% %time%>>"%OUT%\summary.txt"
call vivado -mode batch -source "%~dp0prep_l2.tcl" -log "%OUT%\prep.log" -journal "%OUT%\prep.jou"
echo run_l2 finished %time%>>"%OUT%\summary.txt"
echo finished. See out_l2\summary.txt
endlocal
exit /b 0
