#!/bin/bash

inputfolder=$1

if [ $# -lt 1 ]
then
    echo "Usage: $0 inputdir"
    exit 0
fi

shift


echo Correcting orientation. This needs to be done as dimensions have been swapped so that eddy can run. See README.md notes for more details.
fslswapdim ${inputfolder}/data_gibbs_eddy x -z y ${inputfolder}/data_gibbs_eddy

echo Running dtifit. Fitting FSLs DTI model.
mkdir ${inputfolder}/dtifit_gibbs_eddy
dtifit -k ${inputfolder}/data_gibbs_eddy.nii.gz -m ${inputfolder}/b0_mean_mask.nii.gz -b \
${inputfolder}/bvals -r ${inputfolder}/bvecs_zminxy -o ${inputfolder}/dtifit_gibbs_eddy/dtifit_gibbs_eddy
