syn_dir=syn
if [ $# -gt 1 ]; then
    echo WARNING . This script can have only one argument.
    syn_dir=DCsyn_$1
elif [ $# -eq 1 ]; then
    syn_dir=DCsyn_$1
else
    syn_dir=DCsyn
fi

echo "syn_dir      :" $syn_dir

rm -rf $syn_dir
mkdir $syn_dir
mkdir $syn_dir/mapped $syn_dir/reports
cd $syn_dir

bsub -Is -XF /tools/synopsys/syn/R-2020.09-SP3a/bin/dc_shell -f ../quan_top_dc.tcl