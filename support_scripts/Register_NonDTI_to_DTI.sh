#!/bin/bash

#Script to prepare MRI - MPM, DTI and T2w scans for MMORF, by flirt
    #Criteria - Run Diffusion processing with tensor flags (tensor output from dtifit (so run with the --save_tensor flag))
    # This is not implemented    
         
# Source the project settings
source "project_settings.sh"

subj=$1

#subjlist="20230703_185431_GRIA_52_1_GRIA_T2W_MPM_MTR_Diffusion2_1_3"
#--------------------------------------------------------

#For loop for each subject
#for subj in $subjlist; do

#Change name to simply the subject:
extra_name=$(echo "$subj" | sed -n 's/.*\(MYFR_[0-9]*_[0-9]*[a-z]\).*/\1/p')
echo "${extra_name}"

#Definig 
SubDIR=$projectDIR/${projectname}_data/${projectname}_data_processed/${extra_name}

#Make folder for transformation
transDIR=$SubDIR/MultiModFlirt

mkdir -p $transDIR

#Step 1 - register all data to a common image -> lsq6 using flirt 
    #might need specific steps for DTI modality - or simply use DTI_B0_mean as target
    #Using DTI as a target - specifically, the Mean B0 images now. 

    #Step1A --- Register MPM images to BO
            input=$SubDIR/MPM/MPMCalc/PDW_echo_mean_1_MTR.nii.gz 
            Ref=$SubDIR/DWI/B0_mean.nii.gz
            output=$transDIR/MTR_MPM_LA_to_B0.nii.gz
            transform=$transDIR/trans_LSQ6_MPM_to_DWI_LA.nii.gz

       flirt -in $input -ref $Ref -out $output -omat $transform -dof 6 -noresample 

    #Step1B - Register T2w to B0
            input=$SubDIR/T2w/T2w.nii.gz 
            Ref=$SubDIR/DWI/B0_mean.nii.gz
            output=$transDIR/T2w_LA_to_B0.nii.gz
            transform=$transDIR/trans_LSQ6_T2w_to_DWI_LA.nii.gz

       flirt -in $input -ref $Ref -out $output -omat $transform -dof 6 -noresample 



# Bwloe currently not relevant as only using the specific files that have been trasnformed - if more MPM output because usable - this needs to be adressed
#Step 2 - Apply the transformation to the relevant data

##Take all the inputs data non-DTI and trasnform it to the relevant modality
 
    #the input here, i need to loop though all the relevant outputs from the MPM
    #shopt -s globstar



    #        input=$SubDIR/MPM/MPMCalc/PDW_echo_mean_1_MTR.nii.gz 
   #         Ref=$SubDIR/DWI/B0_mean.nii.gz
  #          output=$transDIR/MTR_MPM_LA_to_B0.nii.gz
 #           transform=$transDIR/trans_LSQ6_MPM_to_DWI_LA.nii.gz

# flirt_app1=`fsl_sub -q veryshort.q -j ${flirt1} -l $scriptDir/logs flirt -in different_modality.nii.gz -ref reference_image.nii.gz -out transformed_different_modality.nii.gz -applyxfm -init transform.mat
