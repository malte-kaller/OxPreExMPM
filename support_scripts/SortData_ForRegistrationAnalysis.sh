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

#Create a folder for Analysis input


#Take relevant folders from the data storage and create a specific output folder
SubDIR=$projectDIR/${projectname}_data/${projectname}_data_processed/${extra_name}
TDir=$projectDIR/${projectname}_data/${projectname}_MBM_Analysis

#If it already exists, remove it create a new one

#--- T2W image files ---

#T2w
mkdir -p $TDir/T2w
#fsl_sub -q veryshort.q -l $scriptDir/logs 
transDIR=$SubDIR/MultiModFlirt
cp $transDIR/T2w_LA_to_B0.nii.gz $TDir/T2w/${extra_name}_T2w.nii.gz

# --- MPM data ---
#MTR
mkdir -p $TDir/MTR
#fsl_sub -q veryshort.q -l $scriptDir/logs 
transDIR=$SubDIR/MultiModFlirt
cp $transDIR/MTR_MPM_LA_to_B0.nii.gz $TDir/MTR/${extra_name}_MTR.nii.gz

#--- DTI copy ---

mkdir -p $TDir/B0_mean
cp $SubDIR/DWI/B0_mean.nii.gz $TDir/B0_mean/${extra_name}_B0_mean.nii.gz

mkdir -p $TDir/FA
cp $SubDIR/DWI/dtifit_gibbs_eddy_FA.nii.gz $TDir/FA/${extra_name}_FA.nii.gz

mkdir -p $TDir/MD
cp $SubDIR/DWI/dtifit_gibbs_eddy_MD.nii.gz $TDir/MD/${extra_name}_MD.nii.gz

mkdir -p $TDir/AD
cp $SubDIR/DWI/dtifit_gibbs_eddy_AD.nii.gz $TDir/AD/${extra_name}_AD.nii.gz

mkdir -p $TDir/RD
cp $SubDIR/DWI/dtifit_gibbs_eddy_RD.nii.gz $TDir/RD/${extra_name}_RD.nii.gz


#done 
