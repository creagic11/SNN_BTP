@echo off
rem A3 fix 2: re-annotate power from the existing gate-level SAIFs (about 3 minutes). From the Vivado Tcl Shell:
rem     cd C:/Users/Anubhav/hush_fpga/fpga
rem     exec -ignorestderr cmd /c annotate3.bat
setlocal
set "OUT=%~dp0..\out_pwr"
call vivado -mode batch -source "%~dp0annotate_power3.tcl" -log "%OUT%\annotate3.log" -journal "%OUT%\annotate3.jou"
echo finished. See out_pwr\summary4.txt
