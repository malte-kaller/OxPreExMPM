#!/bin/bash

#This script runs through all the subject of the project and submits the DWI in the jalapeno/ood based eco-system. 
#Uses the DWI preclinical preprocessing designed by Cristiana.
#This is specific to one shell scripts 

module add fsl
module add fsl_sub

#NOTE: Prequirements to check
 #Raw brukers Subject folder needs to contain DTI data in NIFTI format

# Source the project settings
source "project_settings.sh"

setting=$scriptDIR/project_settings.sh

#Use below to try for a subject
#subjlist="20221115_180439_MYFR_150_1a_noCA_MYFR_T2W_MPM_MTR_Diffusion_1_1"


#--------------------------------------------------------

#For loop for each subject
for subj in $subjlist; do

#Checking Folder and ensureing correct DTI acquisition is name
for a in {1..90}; do
    # Define the path to the 'acqp' file
    filePath="${projectDIR}/${projectname}_rawbrukers/${subj}/${a}/acqp"

    # Check if the file exists before attempting to read from it
    if [ -f "$filePath" ]; then
        # The file exists, read the 13th line
        name=$(sed -n '13p' "$filePath" 2>/dev/null)

        # Check if 'name' contains 'DtiEpi_12_b0'
        if [[ "$name" == *"DtiEpi_b0_BD"* ]]; then
            blipup=$a
        fi

        if [[ "$name" == *"DtiEpi_b2500_BU_30Dir"* ]]; then
            #echo "Folder $a contains the phrase 'DtiEpi_12_b2.5k' in its 'acqp' file."
            shell1=$a

        fi
   #else
        #echo "File $filePath does not exist."
    fi
done

#Define target directory: 
TaDIR=$projectDIR/${projectname}_preprocessing/$subj/DTI_processed

# Remove the directory if it exists - as rerunning of script in existing results leads to error
[ -d "$TaDIR" ] && rm -rf "$TaDIR"

mkdir -p $TaDIR

#===Running pipeline for specific subject

echo "running dwi processing for $subj"

$sup_scriptDIR/diffpostproc_pipeline_full_oneshell_MSK.sh $rawBruDIR/$subj $shell1 $blipup $TaDIR $setting

done 

echo "done"



