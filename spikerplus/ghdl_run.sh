#!/bin/bash
# usage: ghdl_run.sh <generated dir (with output/)> <M> <O> <T> <CW>  ; stim.txt in the generated dir
set -e; d=$1; cd "$d"; rm -rf work; mkdir work
ghdl -i --std=08 --workdir=work output/*.vhd "$(dirname "$0")/tb_network.vhd" >/dev/null
ghdl -m --std=08 --workdir=work -fsynopsys -Wno-binding tb_network >/dev/null
ghdl -r --std=08 --workdir=work -fsynopsys tb_network -gM=$2 -gO=$3 -gT=$4 -gCW=$5 --ieee-asserts=disable >/dev/null
