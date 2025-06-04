#!/bin/bash

#This script submits the script that takes the data processed and sorts into a coherant data structure

# Source the project settings
source "project_settings.sh"

#Subset of subjects for test run of script
#subjlist="20221031_194004_MYFR_150_1g_noCA_MYFR_T2W_MPM_MTR_Diffusion_1_1"

#--------------------------------------------------------

#For loop for each subject
for subj in $subjlist; do

#===Running pipeline for specific subject

echo "Organising data for $subj"

Step1=`fsl_sub -q short -l $scriptDIR/logs/Sort $sup_scriptDIR/SortData_ForSubj.sh $subj`

#Step2=`fsl_sub -q veryshort.q -j ${Step1} -l $scriptDIR/logs/Sort $sup_scriptDIR/Register_NonDTI_to_DTI.sh $subj`

#Step3=`fsl_sub -q veryshort.q -j ${Step2} -l $scriptDIR/logs/Sort $sup_scriptDIR/SortData_ForRegistrationAnalysis.sh $subj`

done 

echo "done"



