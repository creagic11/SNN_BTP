@echo off
rem A3b (28 Oct 2026): full rebuild + gate-level SAIF power for hush_layer v5, unattended (about 4 hours).
rem From the Vivado 2024.1 Tcl Shell:
rem     cd C:/Users/Anubhav/hush_fpga/fpga
rem     exec -ignorestderr cmd /c run_v5.bat
rem Progress: ..\out_v5b\summary.txt   Results: ..\out_v5b\energy.csv
rem (1) prep_v5.tcl in Vivado: 3 timing builds + 3 power builds, netlists, xsim snapshots
rem (2) xsim outside Vivado (it crashed when launched from inside Vivado on this laptop)
rem (3) annotate_v5.tcl in a fresh Vivado: SAIF name fix, read_saif, report_power, energy table
setlocal
set "OUT=%~dp0..\out_v5b"
if not exist "%OUT%" mkdir "%OUT%"
echo run_v5 start %date% %time%>>"%OUT%\summary.txt"
call vivado -mode batch -source "%~dp0prep_v5.tcl" -log "%OUT%\prep.log" -journal "%OUT%\prep.jou"
call :sim base
call :sim mf_gentle
call :sim mf_aggr
call vivado -mode batch -source "%~dp0annotate_v5.tcl" -log "%OUT%\annotate.log" -journal "%OUT%\annotate.jou"
echo run_v5 finished %time%>>"%OUT%\summary.txt"
echo finished. See out_v5b\summary.txt
endlocal
exit /b 0

:sim
if not exist "%OUT%\pwr\%1\saif.tcl" (echo %1: no snapshot, simulation skipped>>"%OUT%\summary.txt" & exit /b 0)
pushd "%OUT%\pwr\%1"
if exist act.saif del /q act.saif
echo %1 sim start %time%>>"%OUT%\summary.txt"
call xsim snap_net -tclbatch saif.tcl -log sim_try1.log
findstr /B /C:"I 19 " sim_try1.log >nul
if errorlevel 1 goto try2
echo %1 sim OK %time%>>"%OUT%\summary.txt"
popd
exit /b 0
:try2
echo %1 sim try1 FAILED, try2 with -debug wave %time%>>"%OUT%\summary.txt"
if exist act.saif del /q act.saif
call xelab tb_net glbl -L unisims_ver -timescale 1ns/1ps -debug wave -s snap_wave > xelab_wave.log 2>&1
call xsim snap_wave -tclbatch saif.tcl -log sim_try2.log
findstr /B /C:"I 19 " sim_try2.log >nul
if errorlevel 1 (echo %1 sim try2 FAILED>>"%OUT%\summary.txt") else (echo %1 sim try2 OK %time%>>"%OUT%\summary.txt")
popd
exit /b 0
