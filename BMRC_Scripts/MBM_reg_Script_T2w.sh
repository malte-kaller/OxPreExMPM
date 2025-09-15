#!/bin/bash

cd /well/lerch/users/flg293/ReTa_Myrf

# Define the path to the Singularity container
CONTAINER=/well/lerch/shared/tools/mice.sif_latest.sif
BIND_PATHS="--bind=/well,/gpfs3"

SE () {
 singularity exec $BIND_PATHS $CONTAINER "$@"
 
}
#This script is desiged to allow an registration with the MBM pipeline

#======Edit input

projName="ReTa_Myrf"
workDIR=/well/lerch/users/flg293/$projName
scriptDIR=$workDIR/scripts/reg/

inputDIR=$workDIR/data/input/
outputDIR=/well/lerch/users/flg293/ReTa_Myrf/reg

inputNAME="T2wReg_N4"
regNAME=${inputNAME}_250909_All

#==========================
mkdir $outputDIR/$regNAME
cd $outputDIR/$regNAME

#:'

SE MBM.py \
 --backend=makeflow \
 --makeflow-opts='-h' \
 --pipeline-name $regNAME \
 --maget-registration-method minctracc \
 --subject-matter mousebrain \
 --init-model /gpfs3/well/lerch/users/flg293/ReTa_Myrf/reg/init_model/oxford-model-2023_T2w/OG.mnc \
 --run-maget \
 --maget-atlas-library /well/lerch/shared/tools/atlases/Dorr_2008_Steadman_2013_Ullmann_2013_Richards_2011_Qiu_2016_Egan_2015_40micron/ex-vivo/ \
 --maget-nlin-protocol /well/lerch/shared/tools/protocols/nonlinear/default_nlin_MAGeT_minctracc_prot.csv \
 --maget-masking-nlin-protocol /well/lerch/shared/tools/protocols/nonlinear/default_nlin_MAGeT_minctracc_prot.csv \
 --lsq12-protocol /well/lerch/shared/tools/protocols/linear/Pydpiper_testing_default_lsq12.csv \
 --no-common-space-registration \
 --lsq6-simple \
 --num-executors 1 \
 --files  $inputDIR/$inputNAME/*BN4def-min-removed.mnc

cat ${regNAME}_makeflow.jx | perl -npe 's/"wall-time"\: 172800/"wall-time": 86400/'>${regNAME}_makeflow_fixed.jx

module load Anaconda3
eval "$(conda shell.bash hook)"
conda activate cctools-env

makeflow -T slurm \
-B '-p short,win' \
--max-remote=500 \
-o stderr.log \
--shared-fs=/well,/gpfs3 \
--singularity=/well/lerch/shared/tools/mice.sif_latest.sif \
--singularity-opt='--bind=/well,/gpfs3' \
--jx ${regNAME}_makeflow_fixed.jx

