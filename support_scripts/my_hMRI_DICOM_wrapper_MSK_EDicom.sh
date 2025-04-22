#!/usr/bin/env bash

# === USAGE ===
# my_hMRI_DICOM_wrapper_MSK_EDicom.sh <subject> <settings_file>
# Called via fsl_sub from the main pipeline

subj=$1
source $2  # e.g., project_settings.sh

# --- Define input/output/log paths ---
input_dir="$rawBruDIR/$subj"
output_dir="$procDIR/$subj/MPM_preprocessing"
logDIR="$scriptDIR/logs/MPM"
mkdir -p "$output_dir" "$logDIR"
log_file="$logDIR/hmri_convert_${subj}.log"

echo "[INFO] Starting DICOM conversion for subject: $subj"
echo "[INFO] Input: $input_dir"
echo "[INFO] Output: $output_dir"
echo "[INFO] Log: $log_file"

# --- Run MATLAB ---
matlab -nojvm -nodesktop -nosplash -r "addpath('$sup_scriptDIR'); hMRI_DICOM_wrapper_EDicom('$input_dir', '$output_dir'); exit;" > "$log_file" 2>&1

exit_code=$?

if [ $exit_code -ne 0 ]; then
  echo "[ERROR] MATLAB DICOM conversion failed for $subj. See log: $log_file"
  exit $exit_code
else
  echo "[SUCCESS] DICOM conversion completed for $subj"
  exit 0
fi