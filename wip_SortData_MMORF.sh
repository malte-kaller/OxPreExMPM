#!/bin/bash

#This script sorts the data for the applying the MMORF registration

#Step by step, what needs to be done: 

#SETUP: All required mdoules 

module add fsl
source "project_settings.sh"

#Define key directories
outDIR=$projectDIR/MMORF_data


#STEP1: Create a directory for the sorted data
mkdir -p $outDIR

#STEP2: Mask T2w data and move to sorted directory 

T2wDIR=$projectDIR/T2wReg_N4
T2wMaskDIR=$projectDIR/T2wReg_N4/masks_T2wN4

# Make the subject list (array) from all *_mask.nii files
##subjectList=$(ls "$T2wMaskDIR"/*_mask.nii | sed -E 's/.*\/(.*)_mask\.nii/\1/' | tr '\n' ' ')
subjectList="MYRF29_1f MYRF30_1h MYRF31_1g"

# Dilate masks for each subject
for subject in $subjectList; do
    in_mask="$T2wMaskDIR/${subject}_mask.nii"
    out_mask="$T2wMaskDIR/${subject}_mask_dil1.nii"
    fslmaths "$in_mask" -dilM -dilM "$out_mask"
done

# now mask the brains and copy it over

for subject in $subjectList; do
mkdir -p $outDIR/$subject/T2w
mkdir -p $outDIR/$subject/Mask
done

for subject in $subjectList; do
    in_T2w="$T2wDIR/${subject}_T2w_BN4def.nii.gz"
    in_mask="$T2wMaskDIR/${subject}_mask_dil1.nii.gz"
    out_mask="$outDIR/Mask/${subject}_mask.nii.gz"
    flirt -in "$in_mask" -ref "$in_T2w" \
      -out "$T2wMaskDIR/${subject}_mask_res2ref.nii" \
      -applyxfm -usesqform -interp nearestneighbour
done

for subject in $subjectList; do
    in_T2w="$T2wDIR/${subject}_T2w_BN4def.nii.gz"
    in_mask="$T2wMaskDIR/${subject}_mask_res2ref.nii"
    out_T2w="$outDIR/${subject}/T2w/T2w.nii.gz"
    fslmaths "$in_T2w" -mas "$in_mask" "$out_T2w"
done

# Copy the masks as well
for subject in $subjectList; do
    in_mask="$T2wMaskDIR/${subject}_mask_res2ref.nii.gz"
    out_mask="$outDIR/${subject}/Mask/mask.nii.gz"
    cp "$in_mask" "$out_mask"
done

#STEP3: Copy DTI data to sorted directory

for subject in $subjectList; do
mkdir -p $outDIR/$subject/DTI
mkdir -p $outDIR/$subject/MPM
done


for subject in $subjectList; do
    out_T2w="$outDIR/${subject}/T2w/T2w.nii.gz"
    in_MD=$projectDIR/**/*${subject}*/DTI_processed/dtifit_gibbs_eddy/dtifit_gibbs_eddy_MD.nii.gz
    out_MD="$outDIR/${subject}/DTI/${subject}_MD.nii.gz"
    
    #If I want to apply linear alingment 
    flirt -in $in_MD -ref "$out_T2w" -out "$out_MD" -omat "$outDIR/${subject}/DTI/DTI_to_T2w.mat" -dof 6 -cost normmi -interp spline

      #-applyxfm -usesqform -interp nearestneighbour
      
done

#now apply this transformation to all the DTI images 
for subject in $subjectList; do
    out_MD="$outDIR/${subject}/DTI/${subject}_MD.nii.gz"
    transform_DTI="$outDIR/${subject}/DTI/DTI_to_T2w.mat"

        for file in $projectDIR/**/*${subject}*/DTI_processed/dtifit_gibbs_eddy/*.nii.gz; do
            #in_file=$projectDIR/**/*${subject}*/DTI_processed/dtifit_gibbs_eddy/$(basename "$file")
            in_file=$file
            in_file=$(ls $in_file)
            base_name=$(basename "$file")
            suffix="${base_name##*_}"
            out_file="$outDIR/${subject}/DTI/$suffix"
            
            #If I just want to copy them over
            cp "$in_file" "$out_file"

            # if I want to apply linear alignment
            #applywarp --in="$in_file" --ref="$out_MD" --premat="$transform_DTI" \
                      #--out="$out_file" --interp=spline
        done

done 

#Mask all the Images in the DTI folder

for subject in $subjectList; do
    in_mask="$outDIR/${subject}/Mask/mask.nii.gz"
    fslmaths "$in_mask" -bin "$in_mask"
    for file in $outDIR/${subject}/DTI/*.nii.gz; do
        out_file="$outDIR/${subject}/DTI/$file"
        fslmaths "$file" -mas "$in_mask" "$file"
    done
done

#STEP4: Copy MPM data to sorted directory


for subject in $subjectList; do
    out_T2w="$outDIR/${subject}/T2w/T2w.nii.gz"
    in_T1=$projectDIR/**/*${subject}*/MPM_preprocessing/SubjectDIR_RepetitionAverage/hMRI_Results_B1/MPMCalc/PDW_echo_mean_1_T1w.nii
    out_T1="$outDIR/${subject}/MPM/${subject}_T1w.nii"
    flirt -in $in_T1 -ref "$out_T2w" \
      -out "$out_T1" -omat "$outDIR/${subject}/MPM/MPM_to_T2w.mat" \
      -dof 6 -cost normmi -interp spline
      #-applyxfm -usesqform -interp nearestneighbour
      
done

#now apply this transformation to all the DTI images 
for subject in $subjectList; do
    out_T1="$outDIR/${subject}/MPM/${subject}_T1w.nii"
    transform_MPM="$outDIR/${subject}/MPM/MPM_to_T2w.mat"

        for file in $projectDIR/**/*${subject}*/MPM_preprocessing/SubjectDIR_RepetitionAverage/hMRI_Results_B1/MPMCalc/*.nii; do
            #in_file=$projectDIR/**/*${subject}*/MPM_preprocessing/SubjectDIR_RepetitionAverage/hMRI_Results_B1/MPMCalc/$(basename "$file")
            in_file=$file
            in_file=$(ls $in_file)
            base_name=$(basename "$file")
            suffix="${base_name##*_}"
            out_file="$outDIR/${subject}/MPM/$suffix"
            
            #just cp the raw files over
            cp "$in_file" "$out_file"

            # If I want to apply linear alignment
            #applywarp --in="$in_file" --ref="$out_T1" --premat="$transform_MPM" \
             #         --out="$out_file" --interp=spline
        done

done 


#Mask all the Images in the DTI folder

for subject in $subjectList; do
    in_mask="$outDIR/${subject}/Mask/mask.nii.gz"
    fslmaths "$in_mask" -bin "$in_mask"
    for file in $outDIR/${subject}/MPM/*.nii.gz; do
        out_file="$outDIR/${subject}/MPM/$file"
        fslmaths "$file" -mas "$in_mask" "$file"
    done
done