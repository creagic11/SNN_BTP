#!/bin/bash
# usage: ghdl_run.sh <generated dir (with output/)> <M> <O> <T> <CW> ; reads stim.txt, writes out.txt in that dir.
# Compiles once (work/ kept); delete <dir>/work to force a rebuild.
set -e; d=$1; cd "$d"
if [ ! -f work/.built ]; then rm -rf work; mkdir work
  ghdl -i --std=08 --workdir=work output/*.vhd "/home/claude/snn_btp/spikerplus/tb_network.vhd" >/dev/null
  ghdl -m --std=08 --workdir=work -fsynopsys -Wno-binding tb_network >/dev/null; touch work/.built; fi
ghdl -r --std=08 --workdir=work -fsynopsys tb_network -gM=$2 -gO=$3 -gT=$4 -gCW=$5 --ieee-asserts=disable >/dev/null
