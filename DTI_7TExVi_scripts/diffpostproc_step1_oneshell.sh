#!/bin/bash
inputdir=$1
shell1=$2
blipDown=$3
outputdir=$4
source $5

#Running locally added scripts to problem solve my own issues
    DTIscriptDIR=$scriptDIR/DTI_7TExVi_scripts

orient_corr () {
fslorient -deleteorient $1
fslswapdim $1 -z -y -x $1
fslorient -setsform 0.1 0 0 0 0 0.1 0 0 0 0 0.1 0 0 0 0 1 $1
fslorient -copysform2qform $1
fslorient -setsformcode 1 $1
fslorient -setqformcode 1 $1
}

foldername=$(echo `basename ${inputdir}`)
substring1=${foldername%_*_*}
substring="${substring1#*_*_}"

nofiles_shell1=`ls ${inputdir}/${shell1}/pdata/1/nifti/ -1 | wc -l`

nofiles=$nofiles_shell1

echo Merging niftis for each shell and checking file integrity.
for i in `seq 1 $nofiles_shell1`
do
  if [[ "$(echo `fslinfo $inputdir/${shell1}/pdata/1/nifti/${substring}_${shell1}_1_${i}.nii ` | head -c 9)" == "data_type" ]]
  then
    printf "$inputdir/${shell1}/pdata/1/nifti/${substring}_${shell1}_1_${i}.nii "  >> $outputdir/filenames
  else
    echo Volume $i from $shell1 is a corrupted volume.Data was likely not acquired correctly. You have to either reacquire your data or use a custom version of the pipeline.
  fi
done

filelist=`cat $outputdir/filenames`

fslmerge -t ${outputdir}/data_merged_original $filelist

echo Copying configuration files over.
cp ${DTIscriptDIR}/masterfiles/acp.txt ${outputdir}/acp.txt
cp ${DTIscriptDIR}/masterfiles/index_oneshell.txt ${outputdir}/index.txt
cp ${DTIscriptDIR}/masterfiles/topup_mouse.cnf ${outputdir}/topup_mouse.cnf

echo Loading bvecs and bvals, preparing them for eddy and dtifit.
cp ${inputdir}/${shell1}/method ${outputdir}/method_shell1
cp ${inputdir}/${blipDown}/pdata/1/nifti/${substring}_${blipDown}_1_1.nii ${outputdir}/b0_blipDown.nii
${DTIscriptDIR}/bin/extract_bvecs_bvals_oneshell_MSK.sh ${outputdir}
${DTIscriptDIR}/bin/swapbvecs ${outputdir}/bvecs -z -y -x ${outputdir}/bvecs_zminxy
${DTIscriptDIR}/bin/swapbvecs ${outputdir}/bvecs_zminxy -z -y -x ${outputdir}/bvecs_eddy

echo Correctly orienting data.
cp ${outputdir}/data_merged_original.nii.gz ${outputdir}/data.nii.gz

#--- not reorientating data here, as it takes this step in Step 3? 
orient_corr ${outputdir}/data.nii.gz

fslroi ${outputdir}/data.nii.gz ${outputdir}/b01 0 1
fslroi ${outputdir}/data.nii.gz ${outputdir}/b02 11 1
fslroi ${outputdir}/data.nii.gz ${outputdir}/b03 22 1

fslmerge -t ${outputdir}/b0s_data ${outputdir}/b01.nii.gz ${outputdir}/b02.nii.gz ${outputdir}/b03.nii.gz

echo Generating mask.
fslmaths ${outputdir}/b0s_data -Tmean ${outputdir}/b0_mean
fslmaths ${outputdir}/b0_mean -thr 200 -dilM -ero -dilM -dilM -dilM -dilM -ero -bin ${outputdir}/b0_mean_mask.nii.gz

echo Removing unnecessary files.
rm ${outputdir}/b02.nii.gz ${outputdir}/b0_mean.nii.gz ${outputdir}/b0s_data.nii.gz
