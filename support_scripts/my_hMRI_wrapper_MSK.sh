#!/usr/bin/env bash

# === USAGE ===
# my_hMRI_wrapper_MSK.sh <subject> <settings_file>
# Called by fsl_sub from the main pipeline

# --- Load subject and settings ---
subj=$1
source $2  # e.g., project_settings.sh

# --- Define paths ---
input_dir="$procDIR/$subj/MPM_preprocessing/SubjectDIR_RepetitionAverage"
defaults_dir="$scriptDIR/"  # Adjust if your defaults are elsewhere
logDIR="$scriptDIR/logs/MPM"
mkdir -p "$logDIR"
log_file="$logDIR/hmri_wrapper_${subj}.log"

# --- Run the hMRI MATLAB wrapper ---
echo "[INFO] Starting hMRI MPM processing for subject: $subj"
echo "[INFO] Input directory: $input_dir"
echo "[INFO] Log: $log_file"

matlab -nojvm -nodesktop -nosplash -r "try, hmri_wrapper_smallbore_MSK('$input_dir', '$defaults_dir'); catch ME, disp(getReport(ME)); exit(1); end; exit(0);" > "$log_file" 2>&1

exit_code=$?

if [ $exit_code -ne 0 ]; then
  echo "[ERROR] MATLAB processing failed for $subj. See log: $log_file"
  exit $exit_code
else
  echo "[SUCCESS] hMRI MPM processing completed for $subj"
  exit 0
fi