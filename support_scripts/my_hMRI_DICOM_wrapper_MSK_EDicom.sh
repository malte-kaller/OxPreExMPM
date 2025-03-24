#!/bin/bash

# Before use:
# - edit your inputs to hMRI_wrapper below!
# - edit the path to the hMRI_wrapper script in the 'cd' command ad the end

# don't run this script directly, but call it using the following script:
# my_hMRI_DICOM_wrapper_submit.sh
# the my_hMRI_DICOM_wrapper_submit.sh script will submit the matlab function to the queue

# Source the project settings
source "project_settings.sh"

#define output directory 

scan=$1
outDIR=$procDIR/$scan/MPM_preprocessing
mkdir -p $outDIR 

# define function to pass the inputs to the hMRI_wapper

my_hMRI_wrapper(){
scan=$1

echo "do "$scan
matlab -nojvm -nodesktop -nosplash -r "hMRI_DICOM_wrapper_EDicom('"$rawBruDIR/$scan"','"$outDIR/$scan"_NIFTI')"

}

# here the function is actually called
# $1 represents the input we are giving to my_hMRI_wrapper.sh (e.g. '01')
cd $sup_scriptDIR
my_hMRI_wrapper $1
cd $scriptDIR
