#!/usr/bin/env bash

# Usage: my_hMRI_DICOM_wrapper_MSK_EDicom.sh <subject> <settings_file>

subj=$1
source $2  # project_settings.sh

input_dir="$rawBruDIR/$subj"
output_dir="$procDIR/$subj/MPM_preprocessing"
log_file="$scriptDIR/logs/MPM/hmri_convert_${subj}.log"

mkdir -p "$output_dir" "$(dirname "$log_file")"

echo "[INFO] Running DICOM wrapper for $subj"
echo "[INFO] Log file: $log_file"

matlab -nojvm -nodesktop -nosplash -r "hMRI_DICOM_wrapper_EDicom('$input_dir', '$output_dir'); exit;" > "$log_file" 2>&1

exit_code=$?

if [ $exit_code -ne 0 ]; then
  echo "[ERROR] MATLAB DICOM conversion failed for $subj. See log: $log_file"
  exit $exit_code
else
  echo "[SUCCESS] DICOM conversion completed for $subj"
  exit 0
fi