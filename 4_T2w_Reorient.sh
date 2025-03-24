#!/bin/bash

#This script creates takes the structural T2W imaging data and corrects the orientation labels to in line with the DWI data.

#---DEFINE BASIC PARAMETERS FOR PROJECT------------------

module add fsl

# Source the project settings
source "project_settings.sh"

#subjlist="20230703_185431_GRIA_52_1_GRIA_T2W_MPM_MTR_Diffusion2_1_3"

subjlist="20250224_084029_MYRD5_1b_MyReach_T2w_DTI_MPM_1_1"


#--------------------------------------------------------

#For loop for each subject
for subj in $subjlist; do

#===Definig input file

# Use grep to find lines containing "T2w", along with the line number (-n option)
t2scan=$(grep -n "T2w" "$rawBruDIR/acquisition_order_"$subj".txt" | cut -d':' -f1)


#Select the right input file from folder
inputfile=$rawBruDIR/$subj/$t2scan/pdata/1/nifti/*_1.nii

#Create output folder 
mkdir -p $procDIR/$subj/T2w_reorientated 
outputfolder=$procDIR/$subj/T2w_reorientated

#Copy file there
cp $inputfile $outputfolder/T2w.nii

outputfile=$outputfolder/T2w.nii
gzip -f $outputfile

orient_corr () {
fslorient -deleteorient $1
fslswapdim $1 z -y x $1
fslorient -setsform 0.1 0 0 0 0 0.1 0 0 0 0 0.1 0 0 0 0 1 $1
fslorient -copysform2qform $1
fslorient -setsformcode 1 $1
fslorient -setqformcode 1 $1
}

orient_corr ${outputfile}.gz

done

echo "done".

