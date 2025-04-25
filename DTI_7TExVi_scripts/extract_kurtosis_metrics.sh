#!/bin/bash

if [ $# -lt 1 ]
then
    echo "Usage: $0 inputdir"
    echo "This script takes kurt1, kurt2 and kurt3 and calculates"
    echo "mean kurtosis (MK), radial kurtosis (RK), and fractional anisotropy of kurtosis (FAK)."
    echo "It assumes that the DKI model with the --kurtdir option has been run"
    echo "using FSL's dtifit and that the outputs are in the input folder."
    echo "Author: A. Martins-Bach. aurea.martins-bach@ndcn.ox.ac.uk"

    exit 0
fi

inputdir=$1
mkdir ${inputdir}/dtifit_gibbs_eddy_kurtdir/tmp

echo "Computing radial kurtosis (RK)"
fslmaths ${inputdir}/dtifit_gibbs_eddy_kurtdir/dtifit_gibbs_eddy_kurtdir_kurt2.nii.gz \
-add ${inputdir}/dtifit_gibbs_eddy_kurtdir/dtifit_gibbs_eddy_kurtdir_kurt3.nii.gz -div 2 -nan ${inputdir}/dtifit_gibbs_eddy_kurtdir/dtifit_gibbs_eddy_kurtdir_RK

echo "Computing mean kurtosis (MK)"
fslmaths ${inputdir}/dtifit_gibbs_eddy_kurtdir/dtifit_gibbs_eddy_kurtdir_kurt1.nii.gz \
-add ${inputdir}/dtifit_gibbs_eddy_kurtdir/dtifit_gibbs_eddy_kurtdir_kurt2.nii.gz \
-add ${inputdir}/dtifit_gibbs_eddy_kurtdir/dtifit_gibbs_eddy_kurtdir_kurt3.nii.gz -div 3 -nan ${inputdir}/dtifit_gibbs_eddy_kurtdir/dtifit_gibbs_eddy_kurtdir_MK

echo "Computing Fractional Anisotropy of kurtosis (FAK)"

for kval in `seq 1 3`
do
fslmaths ${inputdir}/dtifit_gibbs_eddy_kurtdir/dtifit_gibbs_eddy_kurtdir_kurt${kval}.nii.gz \
-sub ${inputdir}/dtifit_gibbs_eddy_kurtdir/dtifit_gibbs_eddy_kurtdir_MK -sqr -nan ${inputdir}/dtifit_gibbs_eddy_kurtdir/tmp/k${kval}_km_sqr
fslmaths ${inputdir}/dtifit_gibbs_eddy_kurtdir/dtifit_gibbs_eddy_kurtdir_kurt${kval}.nii.gz \
-sqr -nan ${inputdir}/dtifit_gibbs_eddy_kurtdir/tmp/k${kval}_sqr
done

fslmaths  ${inputdir}/dtifit_gibbs_eddy_kurtdir/tmp/k1_km_sqr -add ${inputdir}/dtifit_gibbs_eddy_kurtdir/tmp/k2_km_sqr \
-add ${inputdir}/dtifit_gibbs_eddy_kurtdir/tmp/k3_km_sqr -nan ${inputdir}/dtifit_gibbs_eddy_kurtdir/tmp/num

fslmaths ${inputdir}/dtifit_gibbs_eddy_kurtdir/tmp/k1_sqr \
-add ${inputdir}/dtifit_gibbs_eddy_kurtdir/tmp/k2_sqr \
-add ${inputdir}/dtifit_gibbs_eddy_kurtdir/tmp/k3_sqr -nan ${inputdir}/dtifit_gibbs_eddy_kurtdir/tmp/den

fslmaths ${inputdir}/dtifit_gibbs_eddy_kurtdir/tmp/num -div ${inputdir}/dtifit_gibbs_eddy_kurtdir/tmp/den \
-mul 3 -div 2 -sqrt -nan ${inputdir}/dtifit_gibbs_eddy_kurtdir/dtifit_gibbs_eddy_kurtdir_FAK

rm -rf ${inputdir}/dtifit_gibbs_eddy_kurtdir/tmp
