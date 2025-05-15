#!/bin/bash

#This script creates the Mean B0 files of the subject 

#---DEFINE BASIC PARAMETERS FOR PROJECT------------------

# Source the project settings
source $2

#--------------------------------------------------------

#For loop for each subject
subj=$1


dtiDir=$procDIR/$subj/DTI_processed

#===Processing B0 for specific pipline. Assuming B0

# Step 1: Extract the first and the seventeenth volumes
fslroi ${dtiDir}/data.nii.gz ${dtiDir}/b0_1 0 1
fslroi ${dtiDir}/data.nii.gz ${dtiDir}/b0_2 11 1
fslroi ${dtiDir}/data.nii.gz ${dtiDir}/b0_3 22 1

fslmerge -t ${outputdir}/b0s_data ${dtiDir}/b01.nii.gz ${dtiDir}/b02.nii.gz ${dtiDir}/b03.nii.gz

# Step 2: Merge the extracted volumes into a new 4D file
# (This step is optional for averaging just two volumes but included for completeness)
rm -f $dtiDir/merged_volumes_B0.nii.gz
fslmerge -t $dtiDir/merged_volumes_B0.nii.gz ${dtiDir}/b0_1.nii.gz ${dtiDir}/b0_2.nii.gz ${dtiDir}/b0_3.nii.gz

# Step 3: Average the volumes
# Since you're only working with two volumes, you can directly average them without merging, but for demonstration:
fslmaths $dtiDir/merged_volumes.nii.gz -Tmean $dtiDir/B0_mean.nii.gz

#Adjust images accordingly
fslmaths $dtiDir/B0_mean.nii.gz -thr 0 $dtiDir/B0_mean.nii.gz
fslmaths $dtiDir/B0_mean.nii.gz -thrP 2 $dtiDir/B0_mean.nii.gz 

echo "done with $subj"

echo "done"



