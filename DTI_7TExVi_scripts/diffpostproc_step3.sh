#!/bin/bash

outputdir=$1

orient_corr () {
fslorient -deleteorient $1
fslswapdim $1 -z -y -x $1
fslorient -setsform 0.1 0 0 0 0 0.1 0 0 0 0 0.1 0 0 0 0 1 $1
fslorient -copysform2qform $1
fslorient -setsformcode 1 $1
fslorient -setqformcode 1 $1
}

gzip ${outputdir}/b0_blipDown.nii

# added orientation correction here, as mistakes came in here
#orient_corr ${outputdir}/b01.nii.gz

orient_corr ${outputdir}/b0_blipDown.nii.gz
fslmerge -t ${outputdir}/b0_topup ${outputdir}/b01.nii.gz ${outputdir}/b0_blipDown.nii.gz

cp ${outputdir}/data_gibbs.nii.gz ${outputdir}/data_gibbs_cp.nii.gz
cp ${outputdir}/b0_mean_mask.nii.gz ${outputdir}/b0_mean_mask_test.nii.gz

fslswapdim ${outputdir}/data_gibbs_cp x z -y ${outputdir}/data_gibbs_cp
fslswapdim ${outputdir}/b0_mean_mask_test x z -y ${outputdir}/b0_mean_mask_test
fslswapdim ${outputdir}/b0_topup x z -y ${outputdir}/b0_topup
