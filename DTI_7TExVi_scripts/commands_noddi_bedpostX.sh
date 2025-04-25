#!/bin/bash

inputfolder=$1

bedpostx_model=""

if [ $# -lt 1 ]
then
    echo "Usage: $0 inputdir [ advanced options for bedpostx ]"
    echo ""
    echo "<options>:"
    echo "--f0_ardf0 (Add to the model an unattenuated signal compartment; see fsl.fmrib.ox.ac.uk/fsl/fslwiki/FDT/UserGuide for details)"
    echo "--rician (Use Rician noise modelling instead of Gaussian) for the bedpostx model"
    echo ""
    exit 0
fi

shift
while [ ! -z "$1" ]
do
  case "$1" in
    --f0_ardf0) bedpostx_model=$bedpostx_model" --f0 --ardf0";;
    --rician) bedpostx_model=$bedpostx_model" --rician";;
  esac
  shift
done

bedpostx ${inputfolder}/data_noddi_bpx $bedpostx_model

/home/fs0/amyh/func/run_NODDI.sh ${inputfolder}/data_noddi_bpx -m exvivo --dax 0.00047 --diso 0.001 --runMCMC --rician
