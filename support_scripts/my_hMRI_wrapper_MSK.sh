#!/usr/bin/env bash

# === USAGE ===
# my_hMRI_wrapper_MSK.sh <subject> <settings_file>

subj=$1
source $2

input_dir="$procDIR/$subj/MPM_preprocessing/SubjectDIR_RepetitionAverage"
defaults_dir="$scriptDIR/"
logDIR="$scriptDIR/logs/MPM"
mkdir -p "$logDIR"
log_file="$logDIR/hmri_wrapper_${subj}.log"

echo "[INFO] Running hMRI wrapper for $subj"
echo "[INFO] Input: $input_dir"
echo "[INFO] Defaults: $defaults_dir"
echo "[INFO] Logging to: $log_file"

# 🚨 No try/catch or multiline formatting here
matlab -nojvm -nodesktop -nosplash -r "hmri_wrapper_smallbore_MSK('$input_dir', '$defaults_dir'); exit;" > "$log_file" 2>&1

exit_code=$?

if [ $exit_code -ne 0 ]; then
  echo "[ERROR] MATLAB hMRI wrapper failed for $subj. See log: $log_file"
  exit $exit_code
else
  echo "[SUCCESS] hMRI MPM processing completed for $subj"
  exit 0
fi