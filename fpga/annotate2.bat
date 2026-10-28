@echo off
rem A3 fix: re-annotate power from the existing gate-level SAIFs (about 3 minutes). From the Vivado Tcl Shell:
rem     cd C:/Users/Anubhav/hush_fpga/fpga
rem     exec -ignorestderr cmd /c annotate2.bat
setlocal
set "OUT=%~dp0..\out_pwr"
call vivado -mode batch -source "%~dp0annotate_power2.tcl" -log "%OUT%\annotate2.log" -journal "%OUT%\annotate2.jou"
echo finished. See out_pwr\summary3.txt
