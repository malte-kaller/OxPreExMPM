#!/bin/bash
module add mrdegibbs
module add fsl

if [ $# -lt 5 ]
then
    echo "Usage: $0 inputdir exp_no_shell1 exp_no_shell2 exp_no_blipdown outputdir [options]"
    echo ""
    echo "<options>:"
    echo "--run_applytopup: run applytopup after running topup, this is an alternative to eddy"
    echo "--run_dti_shell1: run dti on the first shell only"
    echo "--run_dki_bothshells run dki on both shells"
    echo ""
    echo "Notes: "
    echo "*Part 1 of pipeline (up to Gibbs-ringing correction): data retrieval and organisation which assumes Bruker file structure."
    echo ""
    echo "*Part 2 of pipeline (after and including Gibbs-ringing correction) is more generic and will require organising the files in the pipeline's folder structure and a two-shell dMRI dataset."
    echo ""
    echo "*Pipeline requires a blip reversed (blip down) b=0 image for topup-based estimation of distortions."
    echo ""
    echo "For any questions, please contact cristiana.tisca@linacre.ox.ac.uk."

    exit 0
fi

inputdir=$1
shell1=$2
shell2=$3
blipDown=$4
outputdir=$5

if [ -d "${outputdir}" ];
then
  echo "Output directory exists. Will work there."
else
  mkdir ${outputdir}
fi

shift
while [ ! -z "$1" ]
do
  case "$1" in
    --run_applytopup) applytopup=yes;;
    --run_dti_shell1) dtifit_opt="dti_shell1";;
    --run_dki_bothshells) dtifit_opt="dki_bothshells";;
  esac
  shift
done

echo Part 1 of the pipeline: data retrieval specific to Bruker file structure.
echo Queuing Bruker file handling, orientation correction and mask generation.
jid1=`fsl_sub -q short -l ${outputdir}/logs1 /vols/Data/km/cetisca/projects/diffpostproc-exvivo-mouse-bruker7t/diffpostproc_step1.sh ${inputdir} ${shell1} ${shell2} ${blipDown} ${outputdir}`
echo Jobid $jid1

echo Part 2 of the pipeline:
echo Queuing Gibbs ringing correction.
jid2=`fsl_sub -q short -j $jid1 -l ${outputdir}/ deGibbs3D ${outputdir}/data.nii.gz ${outputdir}/data_gibbs.nii.gz `
echo Jobid $jid2

echo Queuing pretopup file processing
jid3=`fsl_sub -q short -l ${outputdir}/logs3 -j $jid2 /vols/Data/km/cetisca/projects/diffpostproc-exvivo-mouse-bruker7t/diffpostproc_step3.sh ${outputdir}`
echo Jobid $jid3

echo Queuing topup.
jid4=`fsl_sub --coprocessor cuda -q gpu_long -j $jid3 -l ${outputdir}/logs4 topup  --imain=${outputdir}/b0_topup --datain=${outputdir}/acp.txt --config=${outputdir}/topup_mouse.cnf --out=${outputdir}/topup_mouse_output_2b0 --fout=${outputdir}/topup_mouse_field_2b0 --iout=${outputdir}/topup_mouse_unwarped_images_2b0 --logout=${outputdir}/topup_mouse_2b0.log --verbose`
echo Jobid $jid4

echo Queuing post-topup file orientations.
jid5=`fsl_sub -q short -l ${outputdir}/logs4 -j $jid4 /vols/Data/km/cetisca/projects/diffpostproc-exvivo-mouse-bruker7t/diffpostproc_step4.sh ${outputdir}`
echo Jobid $jid5

echo Applytopup:
if [ ! -z $applytopup ]
  then
  echo "Queuing applytopup. Note this is in addition to eddy, whose output is fed into dtifit."
  jid6=`fsl_sub -q short -l ${outputdir}/logsapplytopup -j $jid5 applytopup --imain=${outputdir}/data_gibbs_cp --datain=${outputdir}/acp.txt --inindex=1 --topup=${outputdir}/topup_mouse_output_2b0 --method=jac --out=${outputdir}/data_gibbs_applytopup`
  echo Jobid $jid6
  else
  echo "Applytopup won't be run, option not selected."
fi

echo Queuing eddy cuda.
jid7=`fsl_sub --coprocessor cuda -q gpu_long -j $jid5 -l ${outputdir}/logs4 eddy --imain=${outputdir}/data_gibbs_cp --mask=${outputdir}/b0_mean_mask_test.nii.gz --acqp=${outputdir}/acp.txt --index=${outputdir}/index.txt --bvecs=${outputdir}/bvecs_eddy --bvals=${outputdir}/bvals --topup=${outputdir}/topup_mouse_output_2b0 --out=${outputdir}/data_gibbs_eddy --verbose`
echo Jobid $jid7

echo Queuing dtifit and final file manipulations/organisations before running NODDI and bedpostX.
if [ ! -z $dtifit_opt ]
  then
    if [[ $dtifit_opt == "dti_shell1" ]]
    then
      echo Fitting FSLs DTI model on first shell.
      jid8=`fsl_sub -q short -l ${outputdir}/logs5 -j $jid7 /vols/Data/km/cetisca/projects/diffpostproc-exvivo-mouse-bruker7t/diffpostproc_step5.sh ${outputdir} --dti_shell1`
    elif [[ $dtifit_opt == "dki_bothshells" ]]
    then
      echo Fitting FSL DKI model on both shells.
      jid8=`fsl_sub -q short -l ${outputdir}/logs5 -j $jid7 /vols/Data/km/cetisca/projects/diffpostproc-exvivo-mouse-bruker7t/diffpostproc_step5.sh ${outputdir} --dki_bothshells`
    fi
else
  echo Fitting FSLs DTI model on both shells.
  jid8=`fsl_sub -q short -l ${outputdir}/logs5 -j $jid7 /vols/Data/km/cetisca/projects/diffpostproc-exvivo-mouse-bruker7t/diffpostproc_step5.sh ${outputdir}`
fi
echo Jobid $jid8
