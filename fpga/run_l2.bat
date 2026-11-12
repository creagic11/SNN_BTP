@echo off
rem Implementation run L2 (about 2.5-3 hours). From the Vivado 2024.1 Tcl Shell:
rem     cd <repository>/fpga
rem     exec -ignorestderr cmd /c run_l2.bat
rem Progress and results: ..\out_l2\summary.txt, ..\out_l2\energy_l2.csv
setlocal
set "OUT=%~dp0..\out_l2"
if not exist "%OUT%" mkdir "%OUT%"
echo run_l2 start %date% %time%>>"%OUT%\summary.txt"
call vivado -mode batch -source "%~dp0prep_l2.tcl" -log "%OUT%\prep.log" -journal "%OUT%\prep.jou"
call :sim netpwr\base_ctrl tb_netl1
call vivado -mode batch -source "%~dp0annotate_l2.tcl" -log "%OUT%\annotate.log" -journal "%OUT%\annotate.jou"
echo run_l2 finished %time%>>"%OUT%\summary.txt"
echo finished. See out_l2\summary.txt
endlocal
exit /b 0

:sim
if not exist "%OUT%\%1\saif.tcl" (echo %1: no snapshot, simulation skipped>>"%OUT%\summary.txt" & exit /b 0)
pushd "%OUT%\%1"
if exist act.saif del /q act.saif
echo %1 sim start %time%>>"%OUT%\summary.txt"
call xsim snap_net -tclbatch saif.tcl -log sim_try1.log
findstr /B /C:"I 19 " sim_try1.log >nul
if errorlevel 1 (echo %1 sim FAILED>>"%OUT%\summary.txt") else (echo %1 sim OK %time%>>"%OUT%\summary.txt")
popd
exit /b 0
