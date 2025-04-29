#!/bin/bash

if [ $# -lt 1 ]
then
    echo "Usage: $0 folder_to_cleanup "
    exit 0
fi
inputdir=$1

fslroi ${inputdir}/data_gibbs_eddy.nii.gz ${inputdir}/b01.nii.gz 0 1
fslroi ${inputdir}/data_gibbs_eddy.nii.gz ${inputdir}/b02.nii.gz 16 1
fslroi ${inputdir}/data_gibbs_eddy.nii.gz ${inputdir}/b03.nii.gz 32 1
fslroi ${inputdir}/data_gibbs_eddy.nii.gz ${inputdir}/b04.nii.gz 48 1
fslmerge -t ${inputdir}/b0s_gibbs_eddy ${inputdir}/b01.nii.gz ${inputdir}/b02.nii.gz ${inputdir}/b03.nii.gz ${inputdir}/b04.nii.gz
rm -rf ${inputdir}/data_noddi_bpx.bedpostX
rm ${inputdir}/b01.nii.gz
rm ${inputdir}/b02.nii.gz
rm ${inputdir}/b03.nii.gz
rm ${inputdir}/b04.nii.gz
rm ${inputdir}/data_gibbs_eddy.nii.gz
rm ${inputdir}/data_merged_original.nii.gz
rm ${inputdir}/data_gibbs.nii.gz
rm ${inputdir}/data.nii.gz
rm ${inputdir}/data_gibbs_cp.nii.gz
rm ${inputdir}/data_gibbs_applytopup.nii.gz
rm ${inputdir}/b0s_data.nii.gz
rm ${inputdir}/b0_topup.nii.gz
rm ${inputdir}/b0_mean.nii.gz
rm ${inputdir}/b0_mean_mask.nii.gz
rm ${inputdir}/b0_mean_mask_test.nii.gz
rm ${inputdir}/b0_blipDowncp.nii.gz
rm ${inputdir}/b0_blipDowncp.nii
rm ${inputdir}/b0_blipDown.nii
rm ${inputdir}/acp.txt
rm -rf ${inputdir}/data_noddi_bpx/
rm -rf ${inputdir}/data_noddi_bpx.NODDI_Watson_diff_exvivo/Dtifit
rm ${inputdir}/data_noddi_bpx.NODDI_Watson_diff_exvivo/fintra_samples.nii.gz
rm ${inputdir}/data_noddi_bpx.NODDI_Watson_diff_exvivo/fiso_samples.nii.gz
rm ${inputdir}/data_noddi_bpx.NODDI_Watson_diff_exvivo/irFrac_samples.nii.gz
rm ${inputdir}/data_noddi_bpx.NODDI_Watson_diff_exvivo/kappa_samples.nii.gz
rm ${inputdir}/data_noddi_bpx.NODDI_Watson_diff_exvivo/ph_samples.nii.gz
rm ${inputdir}/data_noddi_bpx.NODDI_Watson_diff_exvivo/th_samples.nii.gz
rm -rf ${inputdir}/data_split
