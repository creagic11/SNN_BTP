@echo off
rem Implementation run L1 (10 Nov 2026), unattended (estimate 5-7 hours). From the Vivado 2024.1 Tcl Shell:
rem     cd <repository>/fpga
rem     exec -ignorestderr cmd /c run_l1.bat
rem Progress: ..\out_l1\summary.txt   Results: ..\out_l1\energy_l1.csv
rem (1) prep_l1.tcl in Vivado: 4 whole-network power builds (+ netlists, xsim snapshots), 2 stream-mode builds,
rem     the Spiker+ build (+ netlist, snapshot)
rem (2) xsim outside Vivado for the 4 network cases and Spiker+ (SAIF over 20 inferences each)
rem (3) annotate_l1.tcl in a fresh Vivado: SAIF name fix, read_saif, report_power, energy table
setlocal
set "OUT=%~dp0..\out_l1"
if not exist "%OUT%" mkdir "%OUT%"
echo run_l1 start %date% %time%>>"%OUT%\summary.txt"
call vivado -mode batch -source "%~dp0prep_l1.tcl" -log "%OUT%\prep.log" -journal "%OUT%\prep.jou"
call :sim netpwr\base tb_netl1
call :sim netpwr\mf_gentle12 tb_netl1
call :sim netpwr\mf_gentler12 tb_netl1
call :sim netpwr\mf_aggr tb_netl1
call :sim spiker tb_spk_net
call vivado -mode batch -source "%~dp0annotate_l1.tcl" -log "%OUT%\annotate.log" -journal "%OUT%\annotate.jou"
echo run_l1 finished %time%>>"%OUT%\summary.txt"
echo finished. See out_l1\summary.txt
endlocal
exit /b 0

:sim
if not exist "%OUT%\%1\saif.tcl" (echo %1: no snapshot, simulation skipped>>"%OUT%\summary.txt" & exit /b 0)
pushd "%OUT%\%1"
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
call xelab %2 glbl -L unisims_ver -timescale 1ns/1ps -debug wave -s snap_wave > xelab_wave.log 2>&1
call xsim snap_wave -tclbatch saif.tcl -log sim_try2.log
findstr /B /C:"I 19 " sim_try2.log >nul
if errorlevel 1 (echo %1 sim try2 FAILED>>"%OUT%\summary.txt") else (echo %1 sim try2 OK %time%>>"%OUT%\summary.txt")
popd
exit /b 0
