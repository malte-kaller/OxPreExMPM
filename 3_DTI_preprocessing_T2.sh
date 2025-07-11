#!/bin/bash

# This script submits DWI preprocessing jobs for all subjects using Cristiana's preclinical pipeline.
# It identifies the shell and blip-up scans from Bruker structure and submits per-subject jobs.

module add fsl
module add fsl_sub

# Load project settings
source "project_settings.sh"
setting=$scriptDIR/project_settings.sh

# For debugging steps: 
# Creating limited subjects:
subjlist="20250611_194551_MYRD8_2a_MyReach_T2w_DTI_MPM_1_1
20250612_192313_MYRD8_2b_MyReach_T2w_DTI_MPM_1_1
20250614_202055_MYRD8_2e_MyReach_T2w_DTI_MPM_1_1
20250615_105715_MYRD8_2f_MyReach_T2w_DTI_MPM_1_1
20250623_192916_MYRD13_1a_MyReach_T2w_DTI_MPM_1_1
20250624_200543_MYRD13_1b_MyReach_T2w_DTI_MPM_1_1
20250625_194802_MYRD13_1d_MyReach_T2w_DTI_MPM_1_1
20250626_194932_MYRD13_1f_MyReach_T2w_DTI_MPM_1_1
20250627_081621_MYRD13_1g_MyReach_T2w_DTI_MPM_1_1
20250627_195007_MYRD13_1c_MyReach_T2w_DTI_MPM_1_1
20250628_081404_MYRD8_2d_MyReach_T2w_DTI_MPM_1_2
20250628_194600_MYRF30_1h_MyReach_T2w_DTI_MPM_2_1_2
20250629_080433_MYRF29_1f_MyReach_T2w_DTI_MPM_2_1_2
20250629_193904_MYRF31_1g_MyReach_T2w_DTI_MPM_2_1_2"

# Prepare log directory for this script
logDIR="$scriptDIR/logs/DTI"
mkdir -p "$logDIR"

# For loop for each subject
for subj in $subjlist; do

  # Identify shell1 and blipup from acqp files
  for a in {1..90}; do
    filePath="${projectDIR}/${projectname}_rawbrukers/${subj}/${a}/acqp"
    if [ -f "$filePath" ]; then
      name=$(sed -n '13p' "$filePath" 2>/dev/null)
      if [[ "$name" == *"DtiEpi_b0_BD"* ]]; then
        blipup=$a
      fi
      if [[ "$name" == *"DtiEpi_b2500_BU_30Dir"* ]]; then
        shell1=$a
      fi
    fi
  done

  # Define output directory
  TaDIR=$projectDIR/${projectname}_preprocessing/$subj/DTI_processed
  #[ -d "$TaDIR" ] && rm -rf "$TaDIR"
  #mkdir -p "$TaDIR"

  # Log file for this subject
  subj_log="$logDIR/dti_pipeline_${subj}.log"
  mkdir -p "$(dirname "$subj_log")"  # Not strictly necessary here, but safe

  echo "[INFO] Submitting DTI processing for subject: $subj"
  echo "[INFO] shell1=$shell1, blipup=$blipup" > "$subj_log"

  bash $sup_scriptDIR/diffpostproc_pipeline_full_oneshell_MSK_local.sh \
    "$rawBruDIR/$subj" "$shell1" "$blipup" "$TaDIR" "$setting" >> "$subj_log" 2>&1

  if [ $? -ne 0 ]; then
    echo "[ERROR] DTI pipeline failed for $subj. Check log: $subj_log"
  else
    echo "[SUCCESS] DTI pipeline completed for $subj. Log: $subj_log"
  fi

done

echo "All DTI processing jobs submitted. Check logs in $logDIR."