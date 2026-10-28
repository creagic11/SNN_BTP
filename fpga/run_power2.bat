@echo off
rem A3 retry (28 Oct): run the gate-level SAIF simulations OUTSIDE Vivado (the first run's xsim crashed with
rem EXCEPTION_ACCESS_VIOLATION while loading, launched from inside the Vivado batch process with ~4.4 GB virtual
rem memory left), then annotate power in a fresh Vivado. Builds, netlists and xsim snapshots from run_power.tcl
rem are reused. Per case: try 1 = existing snapshot (debug typical); try 2 = rebuilt snapshot with -debug wave;
rem diagnostic = plain run without SAIF if both fail. Run from the Vivado 2024.1 Tcl Shell:
rem     cd C:/Users/Anubhav/hush_fpga/fpga
rem     exec -ignorestderr cmd /c run_power2.bat
setlocal
set "OUT=%~dp0..\out_pwr"
echo run_power2 start %date% %time%>"%OUT%\summary2.txt"
call :sim base
call :sim mf_gentle
call :sim mf_aggr
echo annotate start %time%>>"%OUT%\summary2.txt"
call vivado -mode batch -source "%~dp0annotate_power.tcl" -log "%OUT%\annotate.log" -journal "%OUT%\annotate.jou"
echo ALL DONE %time%>>"%OUT%\summary2.txt"
endlocal
exit /b 0

:sim
pushd "%OUT%\%1"
if exist act.saif del /q act.saif
echo %1 try1 start %time%>>"%OUT%\summary2.txt"
call xsim snap_net -tclbatch saif.tcl -log sim_try1.log
findstr /B /C:"I 19 " sim_try1.log >nul
if errorlevel 1 goto try2
echo %1 try1 OK %time%>>"%OUT%\summary2.txt"
popd
exit /b 0
:try2
echo %1 try1 FAILED, try2 (-debug wave) start %time%>>"%OUT%\summary2.txt"
if exist act.saif del /q act.saif
call xelab tb_net glbl -L unisims_ver -timescale 1ns/1ps -debug wave -s snap_wave > xelab_wave.log 2>&1
call xsim snap_wave -tclbatch saif.tcl -log sim_try2.log
findstr /B /C:"I 19 " sim_try2.log >nul
if errorlevel 1 goto diag
echo %1 try2 OK %time%>>"%OUT%\summary2.txt"
popd
exit /b 0
:diag
echo %1 try2 FAILED, diagnostic run without SAIF %time%>>"%OUT%\summary2.txt"
call xsim snap_net -R -log sim_plain.log
findstr /B /C:"I 19 " sim_plain.log >nul
if errorlevel 1 (echo %1 diagnostic: plain simulation also FAILED>>"%OUT%\summary2.txt") else (echo %1 diagnostic: plain simulation OK, SAIF logging is the problem>>"%OUT%\summary2.txt")
popd
exit /b 0
