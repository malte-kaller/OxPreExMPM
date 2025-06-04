#!/usr/bin/env bash

#This script copies all the relevant data from the preprocessing steps and organsises them in organised format.

# Source the project settings
source "project_settings.sh"

subj=$1

#====Trasnferring data in the correct format====

#For loop for each subject
#for subj in $subjlist; do

 echo "copying data for $subj"

	#Change name to simply the subject: 
	extra_name=$(echo "$subj" | sed -n 's/.*\(MYFR_[0-9]*_[0-9]*[a-z]\).*/\1/p')
echo "${extra_name}"

#Create a subject folder
TDir=$projectDIR/${projectname}_data/${projectname}_data_processed
SubDIR=$TDir/${extra_name}

rm -f -r  $SubDIR

mkdir -p $SubDIR

#--- T2W image files ---
#Pick out the relevant datafiles
#fsl_sub -q veryshort.q 

#T2w
mkdir -p $SubDIR/T2w
#fsl_sub -q veryshort.q -l $scriptDir/logs 
cp $procDIR/$subj/T2w_reorientated/T2w.nii.gz $SubDIR/T2w/T2w.nii.gz

#--- DTI processing and copy ---

dtiDir=$procDIR/$subj/DTI_processed

#Make Directories 
mkdir -p $SubDIR/DWI
TDIR=$SubDIR/DWI

#fsl_sub -q veryshort.q -l $scriptDir/logs 
cp $dtiDir/B0_mean.nii.gz  $TDIR/B0_mean.nii.gz
#fsl_sub -q veryshort.q -l $scriptDir/logs cp $dtiDir/B0_mean.nii.gz  $TDIR/B0_mean/B0_mean.nii.gz 
#fsl_sub -q veryshort.q -l $scriptDir/logs 
cp $dtiDir/dtifit_gibbs_eddy/**  $TDIR/
#fsl_sub -q veryshort.q -l $scriptDir/logs cp $dtiDir/dtifit_gibbs_eddy/dtifit_gibbs_eddy_MD.nii.gz  $TDir/MD/sub_${extra_name}_MD.nii.gz

#processing RD and AD
fslmaths $TDIR/dtifit_gibbs_eddy_L2.nii.gz -add $TDIR/dtifit_gibbs_eddy_L3.nii.gz -div 2 $TDIR/dtifit_gibbs_eddy_RD.nii.gz
cp $TDIR/dtifit_gibbs_eddy_L1.nii.gz $TDIR/dtifit_gibbs_eddy_AD.nii.gz

# ---- MPM data ---

#MPM data 
mkdir -p $SubDIR/MPM
TDir=$SubDIR/MPM

#Start with MPMcalc data
MPMDIR=$procDIR/$subj/MPM_preprocessing/${subj}_NIFTI/SubjectDIR_RepetitionAverage/hMRI_Results_noB1mapping 
#cp1=`fsl_sub -q veryshort.q -l $scriptDir/logs 
cp -r $MPMDIR/MPMCalc $TDir
#cp2=`fsl_sub -q veryshort.q -l $scriptDir/logs 
cp -r $MPMDIR/Results $TDir

#Gzip data and reorient 
#gzip1=`fsl_sub -q veryshort.q -j ${cp1} -l $scriptDir/logs 
gzip -f $TDir/MPMCalc/*.nii
#gzip2=`fsl_sub -q veryshort.q -j ${cp2} -l $scriptDir/logs 
gzip -f $TDir/Results/*.nii
#gzip3=`fsl_sub -q veryshort.q -j ${cp2} -l $scriptDir/logs 
gzip -f $TDir/Results/S*/*nii

# Loop through all .nii.gz files in MPMDIR and its subdirectories
find "$TDir" -type f -name "*.nii.gz" | while read -r file; do
    echo "Processing file: $file"

#Reorient data
name=$file

orient_corr () {
fslorient -deleteorient $1
fslswapdim $1 -z -y -x $1
fslorient -setsform 0.1 0 0 0 0 0.1 0 0 0 0 0.1 0 0 0 0 1 $1
fslorient -copysform2qform $1
fslorient -setsformcode 1 $1
fslorient -setqformcode 1 $1
}

#or1=`fsl_sub -q veryshort.q -j ${gzip3} -l $scriptDir/logs 
orient_corr $name 

done
#done
