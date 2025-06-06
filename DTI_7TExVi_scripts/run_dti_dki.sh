inputfolder=$1

if [ $# -lt 1 ]
then
    echo "Usage: $0 inputdir"
    echo ""
    echo "<options>:"
    echo "-dti_shell1 (Run FSL's dtifit on first shell)"
    echo "-dki_bothshells (Run FSL's DKI implementation --diffkurt on both shells)"
    echo ""
    exit 0
fi

shift
while [ ! -z "$1" ]
do
  case "$1" in
    -run_dti_shell1) dtifit_opt="dti_shell1";;
    -run_dki_bothshells) dtifit_opt="dki_bothshells";;
  esac
  shift
done

echo Running dtifit.
if [[ -z $dtifit_opt ]]
  then
    echo Fitting FSLs DTI model on all volumes/both shells.
    mkdir ${inputfolder}/dtifit_gibbs_eddy_bothshells
    dtifit -k ${inputfolder}/data_gibbs_eddy.nii.gz -m ${inputfolder}/b0_mean_mask.nii.gz -b \
    ${inputfolder}/bvals -r ${inputfolder}/bvecs_zminxy -o ${inputfolder}/dtifit_gibbs_eddy_bothshells/dtifit_gibbs_eddy_bothshells
  elif [[ $dtifit_opt == "dti_shell1" ]]
  then
    echo Fitting FSLs DTI model on first shell only.
    mkdir ${inputfolder}/dtifit_gibbs_eddy_firstshell
    select_dwi_vols ${inputfolder}/data_gibbs_eddy ${inputfolder}/bvals \
    ${inputfolder}/data_gibbs_eddy_firstshell 0 -b 2500 -obv ${inputfolder}/bvecs_zminxy
    dtifit -k ${inputfolder}/data_gibbs_eddy_firstshell.nii.gz -m ${inputfolder}/b0_mean_mask.nii.gz -b \
    ${inputfolder}/data_gibbs_eddy_firstshell.bval -r ${inputfolder}/data_gibbs_eddy_firstshell.bvec \
    -o ${inputfolder}/dtifit_gibbs_eddy_firstshell/dtifit_gibbs_eddy_firstshell
  elif [[ $dtifit_opt == "dki_bothshells" ]]
  then
    echo Fitting FSLs DKI model --kurtdir
    mkdir ${inputfolder}/dtifit_gibbs_eddy_kurtdir
    dtifit -k ${inputfolder}/data_gibbs_eddy.nii.gz -m ${inputfolder}/b0_mean_mask.nii.gz -b \
    ${inputfolder}/bvals -r ${inputfolder}/bvecs_zminxy \
    -o ${inputfolder}/dtifit_gibbs_eddy_kurtdir/dtifit_gibbs_eddy_kurtdir --kurtdir
fi
