#!/bin/bash

module add mrdegibbs
module add fsl

# Parse input arguments
if [ $# -lt 4 ]; then
    echo "Usage: $0 inputdir exp_no_shell1 exp_no_blipdown outputdir [settings_file] [--run_applytopup]"
    exit 1
fi

inputdir=$1
shell1=$2
blipDown=$3
outputdir=$4
source $5
settings_file=$5 
shift 5


#================= Local debugging =======================
   
    #Running locally added scripts to problem solve my own issues
    DTIscriptDIR=$scriptDIR/DTI_7TExVi_scripts

# Optional flag for applytopup
# (if not provided, the script will not run applytopup)
applytopup=""

while [ ! -z "$1" ]; do
  case "$1" in
    --run_applytopup) applytopup="yes" ;;
  esac
  shift
done

if [ ! -d "$outputdir" ]; then
  echo "[INFO] Creating output directory: $outputdir"
  mkdir -p "$outputdir"
else
  echo "[INFO] Output directory exists: $outputdir"
fi

logDIR="$scriptDIR/DTI"
mkdir -p "$logDIR"/logs{1,2,3,4,5,applytopup}

# === STEP 1: Bruker to NIfTI conversion and organisation ===
echo "[STEP 1] Converting and organising Bruker files..."
jid1=$(fsl_sub -q short -N "dti_step1_${subj}" -l "$logDIR/logs1" \
  $DTIscriptDIR/diffpostproc_step1_oneshell.sh \
  "$inputdir" "$shell1" "$blipDown" "$outputdir" "$settings_file")
echo "  → Job ID: $jid1"

#: <<'COMMENT_BLOCK'
# === STEP 2: Gibbs ringing correction ===
echo "[STEP 2] Running Gibbs ringing correction..."
jid2=$(fsl_sub -q short -N "dti_step2_gibbs_${subj}" -j $jid1 -l "$logDIR/logs2" \
  deGibbs3D "$outputdir/data.nii.gz" "$outputdir/data_gibbs.nii.gz")
echo "  → Job ID: $jid2"

# === STEP 3: Pre-topup processing ===
echo "[STEP 3] Pre-topup processing..."
jid3=$(fsl_sub -q short -N "dti_step3_prep_${subj}" -j $jid2 -l "$logDIR/logs3" \
  $DTIscriptDIR/diffpostproc_step3.sh "$outputdir")
echo "  → Job ID: $jid3"

# === STEP 4: Topup correction ===
echo "[STEP 4] Running topup..."
jid4=$(fsl_sub --coprocessor cuda -q gpu_long -N "dti_step4_topup_${subj}" -j $jid3 -l "$logDIR/logs4" \
  topup --imain="$outputdir/b0_topup" \
        --datain="$outputdir/acp.txt" \
        --config="$outputdir/topup_mouse.cnf" \
        --out="$outputdir/topup_mouse_output_2b0" \
        --fout="$outputdir/topup_mouse_field_2b0" \
        --iout="$outputdir/topup_mouse_unwarped_images_2b0" \
        --logout="$outputdir/topup_mouse_2b0.log" --verbose)
echo "  → Job ID: $jid4"

# === STEP 5: Post-topup orientation correction ===
echo "[STEP 5] Correcting post-topup orientations..."
jid5=$(fsl_sub -q short -N "dti_step5_orient_${subj}" -j $jid4 -l "$logDIR/logs4" \
  $DTIscriptDIR/diffpostproc_step4.sh "$outputdir")
echo "  → Job ID: $jid5"

# === OPTIONAL: Applytopup ===
if [ ! -z "$applytopup" ]; then
  echo "[OPTIONAL] Applying topup correction to data..."
  jid6=$(fsl_sub -q short -N "dti_applytopup_${subj}" -j $jid5 -l "$logDIR/logsapplytopup" \
    applytopup --imain="$outputdir/data_gibbs_cp" \
               --datain="$outputdir/acp.txt" \
               --inindex=1 \
               --topup="$outputdir/topup_mouse_output_2b0" \
               --method=jac \
               --out="$outputdir/data_gibbs_applytopup")
  echo "  → Job ID: $jid6"
  final_dependency=$jid6
else
  echo "[INFO] Applytopup not requested — skipping."
   final_dependency=$jid5
fi

# === STEP 6: Eddy correction ===
echo "[STEP 6] Running eddy correction..."
jid7=$(fsl_sub --coprocessor cuda -q gpu_long -N "dti_step6_eddy_${subj}" -j $final_dependency -l "$logDIR/logs4" \
  eddy --imain="$outputdir/data_gibbs_cp" \
       --mask="$outputdir/b0_mean_mask_test.nii.gz" \
       --acqp="$outputdir/acp.txt" \
       --index="$outputdir/index.txt" \
       --bvecs="$outputdir/bvecs_eddy" \
       --bvals="$outputdir/bvals" \
       --topup="$outputdir/topup_mouse_output_2b0" \
       --out="$outputdir/data_gibbs_eddy" --verbose)
echo "  → Job ID: $jid7"

# === STEP 7: Fit tensor and clean up ===
echo "[STEP 7] Running DTI fitting and final steps..."
jid8=$(fsl_sub --coprocessor cuda -q gpu_long -N "dti_step7_dtifit_${subj}" -j $jid7 -l "$logDIR/logs5" \
  $DTIscriptDIR/diffpostproc_step5_oneshell.sh "$outputdir")
echo "  → Job ID: $jid8"

# === STEP 8: Mean B0 calculation ===
echo "[STEP 8] Calculating mean B0..."
jid9=$(fsl_sub -q short -N "dti_step8_b0mean_${subj}" -j $jid8 -l "$logDIR/logs5" \
  "$sup_scriptDIR/diffpostproc_MeanB0calc.sh" "$subj")
echo "  → Job ID: $jid9"
#COMMENT_BLOCK



