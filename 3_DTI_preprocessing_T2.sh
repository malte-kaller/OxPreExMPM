#!/bin/bash

# This script submits DWI preprocessing jobs for all subjects using Cristiana's preclinical pipeline.
# It identifies the shell and blip-up scans from Bruker structure and submits per-subject jobs.

module add fsl
module add fsl_sub

# Load project settings
source "project_settings.sh"
setting=$scriptDIR/project_settings.sh

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
  [ -d "$TaDIR" ] && rm -rf "$TaDIR"
  mkdir -p "$TaDIR"

  # Log file for this subject
  subj_log="$logDIR/DTI/dti_pipeline_${subj}.log"

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
