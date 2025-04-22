#!/usr/bin/env bash

# === USAGE ===
# my_hMRI_wrapper_MSK.sh <subject> <settings_file>
# Called via fsl_sub from the main pipeline

subj=$1
source $2  # e.g., project_settings.sh

# --- Define input/output/log paths ---
input_dir="$procDIR/$subj/MPM_preprocessing/SubjectDIR_RepetitionAverage"
defaults_dir="$sup_scriptDIR"  # Adjust if defaults file lives elsewhere
logDIR="$scriptDIR/logs/MPM"
mkdir -p "$logDIR"
log_file="$logDIR/hmri_wrapper_${subj}.log"

echo "[INFO] Starting hMRI MPM wrapper for subject: $subj"
echo "[INFO] Input: $input_dir"
echo "[INFO] Defaults dir: $defaults_dir"
echo "[INFO] Log: $log_file"

# --- Run MATLAB ---
matlab -nojvm -nodesktop -nosplash -r "addpath('$sup_scriptDIR'); hmri_wrapper_smallbore_MSK('$input_dir', '$defaults_dir'); exit;" > "$log_file" 2>&1

exit_code=$?

if [ $exit_code -ne 0 ]; then
  echo "[ERROR] MATLAB MPM wrapper failed for $subj. See log: $log_file"
  exit $exit_code
else
  echo "[SUCCESS] MPM wrapper completed for $subj"
  exit 0
fi