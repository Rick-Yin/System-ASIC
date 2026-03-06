#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: you need to run power_start.tcl <lvl> <method>"
    echo "lvl : 3 | 4 | 5"
    echo "method: UQ | SPNQ"
    exit 1
fi

LVL="$1"
METHOD="$2"

WORKDIR="DCsyn_lvl${LVL}_${METHOD}"
DC_TCL="pt_analyse.tcl"
OUTDIR="./power"
NETLIST="./mapped/viterbi_quan_lvl${LVL}_${METHOD}-mapped.v"
TB_FILE="../DC_tb/tb_lvl${LVL}_${METHOD,,}.v"
SIM="sim_lvl${LVL}_${METHOD}"
BSUB="bsub -Is -XF"

cd $WORKDIR

mkdir -p ${OUTDIR}

${BSUB} vcs -full64 \
    -debug_access+all ${NETLIST} ${TB_FILE} \
    -timescale=1ns/1ps \
    -f ../DC_tb/post_worst_sim.f \
    -o ${SIM}

${BSUB} ./${SIM}

export LVL METHOD

${BSUB} /tools/synopsys/prime/V-2023.12/bin/pt_shell -file ../${DC_TCL}