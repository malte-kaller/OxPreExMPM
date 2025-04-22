#!/usr/bin/env bash

# This script prepares MPM echoes from multiple repetitions for hMRI

module add fsl
module add fsl_sub

source $2

# This script prepares MPM echoes from multiple repetitions for hMRI
# register each repetition/echo to the same space and create average of echoes
# definitions of paths

#Definition of subject
subj=$1

dataDir=$rawBruDIR
workDir=$procDIR
scriptDir=$scriptDIR

subDir="$procDIR"/"$subj"/MPM_preprocessing/
workDir=$subDir

# B1DIR
# 	B1_struct.nii (the DAM40 file)
# 	B1_map.nii (scaled to center around 100)

# crete new folders for output
outDir=$workDir/SubjectDIR_RepetitionAverage
mkdir -p $outDir/B1DIR

S1=$workDir/DAM/B1map_struct.nii #with flip angle alpha
referenceScan=$(cat "$scriptDir"/acquisition_order_files/PD/PD_"$subj".txt | head -n 1)

# register 40 FA map to the reference average
flirt -in $S1 -ref $referenceScan/repetition_average.nii -out $outDir/B1DIR/B1_struct_registered -omat $outDir/B1DIR/B1map_transform.mat -interp spline -dof 6

# smooth B1 map in native space
fslmaths $workDir/DAM/B1map_DAM.nii.gz -nan -s 0.5 $outDir/B1DIR/B1map_DAM_smoothed_0.5

# apply transform to the smoothed B1 map
flirt -in $outDir/B1DIR/B1map_DAM_smoothed_0.5 -ref $referenceScan/repetition_average.nii -applyxfm -init $outDir/B1DIR/B1map_transform.mat -out $outDir/B1DIR/B1map_DAM_registered.nii -interp trilinear -dof 6

# smooth both FA40 and B1 map to reduce interpolation artefact
# fslmaths $outDir/B1DIR/B1_struct_registered -s 0.4 $outDir/B1DIR/B1_registered_smoothed_0.4
# fslmaths $outDir/B1DIR/B1map_DAM_registered -s 0.4 $outDir/B1DIR/B1map_DAM_registered_smoothed_0.4

#turn both FA40 and B1 map maps into .nii
gunzip $outDir/B1DIR/B1_struct_registered.nii
gunzip $outDir/B1DIR/B1map_DAM_registered.nii
cp $workDir/DAM/B1map_struct.json $outDir/B1DIR/B1_struct_registered.json

