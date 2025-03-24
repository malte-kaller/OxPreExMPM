#!/usr/bin/env bash

module add fsl
module add fsl_sub
source $5

# This script prepares MPM echoes from multiple repetitions for hMRI
# register each repetition/echo to the same space and create average of echoes
# definitions of paths

dataDir=$rawBruDIR
workDir=$procDIR
scriptDir=$scriptDIR

#Definition of subject
subj=$1

#Map Types and specific name of files
maptype="MT T1 PD"

MTfile=$2
PDfile=$3
T1file=$4

# create new folders for output
subDir="$workDir"/"$subj"/MPM_preprocessing/"$subj"_NIFTI
outDir="${subDir}"/SubjectDIR_RepetitionAverage
mkdir -p $outDir

#Create a record of all the files in a text document 
rm "$scriptDIR"/acquisition_order_files/MT/MT_"$subj".txt
rm "$scriptDIR"/acquisition_order_files/PD/PD_"$subj".txt
rm "$scriptDIR"/acquisition_order_files/T1/T1_"$subj".txt

mkdir -p "$scriptDIR"/acquisition_order_files/MT
ls -d "$subDir"/$MTfile* >> "$scriptDIR"/acquisition_order_files/MT/MT_"$subj".txt

mkdir -p "$scriptDIR"/acquisition_order_files/PD
ls -d "$subDir"/$PDfile* >> "$scriptDIR"/acquisition_order_files/PD/PD_"$subj".txt

mkdir -p ${scriptDIR}/acquisition_order_files/T1
ls -d "$subDir"/$T1file* >> "$scriptDIR"/acquisition_order_files/T1/T1_"$subj".txt

#Create a loop for each modality 
for map in $maptype; do

  echo "$map"

  referenceScan=$(cat "$scriptDIR"/acquisition_order_files/"$map"/"$map"_"$subj".txt | head -n 1)

      # for each repetition
      for repetition in $(cat "$scriptDIR"/acquisition_order_files/"$map"/"$map"_"$subj".txt); do

      echo "$repetition"

      # take average of echoes within the same repetition
      fslmerge -t $repetition/repetition_sum.nii.gz $repetition/*.nii.gz
      fslmaths $repetition/repetition_sum.nii.gz -Tmean $repetition/repetition_average.nii.gz
      rm $repetition/repetition_sum.nii.gz

      # register to the first repetition's average of echoes with 6DOF, Search cost set to normmi
      flirt1=`fsl_sub -q short -l $scriptDir/logs/MPM/regrep flirt -in $repetition/repetition_average.nii.gz -ref $referenceScan/repetition_average.nii.gz -out $repetition/repetition_average_registered.nii.gz -omat $repetition/repetition_average_transform.mat -interp spline -dof 6 -searchcost normmi -cost normmi`

        # apply registration transform to all echoes
        for a in {1..8}; do
        echo "echo number $a"
        flirt2=`fsl_sub -q short -j ${flirt1} -l $scriptDir/logs/MPM/regrep flirt -in $repetition/MF*_echo_000"$((a-1))".nii.gz -ref $referenceScan/repetition_average.nii.gz -applyxfm -init $repetition/repetition_average_transform.mat -out $repetition/coregistered_echo_"$a" -interp spline -dof 6`
        done

      echo "done with $repetition"

      done

  # crete new folder for the average of repetitions
  mkdir -p $outDir/"$map"wDIR
  # Copy json from raw echo to the average of repetitions for each echo
  for a in {1..8}; do
  cp1=`fsl_sub -q short -j ${flirt2} -l $scriptDir/logs/MPM/regrep cp $referenceScan/MF*_echo_000"$((a-1))".json $outDir/"$map"wDIR/`
  mv1=`fsl_sub -q short -j ${cp1} -l $scriptDir/logs/MPM/regrep mv $outDir/"$map"wDIR/MF*_echo_000"$((a-1))".json $outDir/"$map"wDIR/"$map"W_echo_mean_"$a".json`
  done

echo "done"

done


# average the echoes across repetitions into the output folder
for a in {1..8}; do
echo "echo number $a"

# MT
fslmerge1=`fsl_sub -q short -j ${mv1} -l $scriptDir/logs/MPM/regrep fslmerge -t $outDir/MTwDIR/repetition_sum_"$a".nii $subDir/${MTfile}*/coregistered_echo_"$a".nii.gz`
fslmaths1=`fsl_sub -q short -j ${fslmerge1} -l $scriptDir/logs/MPM/regrep fslmaths $outDir/MTwDIR/repetition_sum_"$a".nii -Tmean $outDir/MTwDIR/MTW_echo_mean_"$a".nii`
rm1=`fsl_sub -q short -j ${fslmaths1} -l $scriptDir/logs/MPM/regrep rm $outDir/MTwDIR/repetition_sum_"$a".nii.gz`

# T1
fslmerge2=`fsl_sub -q short -j ${rm1} -l $scriptDir/logs/MPM/regrep fslmerge -t $outDir/T1wDIR/repetition_sum_"$a".nii $subDir/${T1file}*/coregistered_echo_"$a".nii.gz`
fslmaths2=`fsl_sub -q short -j ${fslmerge2} -l $scriptDir/logs/MPM/regrep fslmaths $outDir/T1wDIR/repetition_sum_"$a".nii -Tmean $outDir/T1wDIR/T1W_echo_mean_"$a".nii`
rm1=`fsl_sub -q short -j ${fslmaths2} -l $scriptDir/logs/MPM/regrep rm $outDir/T1wDIR/repetition_sum_"$a".nii.gz`

# PD
fslmerge3=`fsl_sub -q short -j ${rm1} -l $scriptDir/logs/MPM/regrep fslmerge -t $outDir/PDwDIR/repetition_sum_"$a".nii $subDir/${PDfile}*/coregistered_echo_"$a".nii.gz`
fslmaths3=`fsl_sub -q short -j ${fslmerge3} -l $scriptDir/logs/MPM/regrep fslmaths $outDir/PDwDIR/repetition_sum_"$a".nii -Tmean $outDir/PDwDIR/PDW_echo_mean_"$a".nii`
rm1=`fsl_sub -q short -j ${fslmaths3} -l $scriptDir/logs/MPM/regrep rm $outDir/PDwDIR/repetition_sum_"$a".nii.gz`

done

echo "===SCRIPT DONE==="
