#!/usr/bin/env bash

# === USAGE ===
# my_hMRI_DICOM_wrapper_MSK_EDicom.sh <subject> <settings_file>
# Called by fsl_sub from the main pipeline

# --- Load subject and settings ---
subj=$1
source $2  # e.g., project_settings.sh

# --- Define input and output paths ---
input_dir="$rawBruDIR/$subj"
output_dir="$procDIR/$subj/MPM_preprocessing"
log_file="$output_dir/hmri_convert_${subj}.log"

mkdir -p "$output_dir"

# --- Run the DICOM conversion in MATLAB ---
echo "[INFO] Starting DICOM conversion for subject: $subj"
echo "[INFO] Input dir: $input_dir"
echo "[INFO] Output dir: $output_dir"
echo "[INFO] Log file: $log_file"

matlab -nojvm -nodesktop -nosplash -r "
try
  hMRI_DICOM_wrapper('$input_dir', '$output_dir');
catch ME
  disp(getReport(ME));
  exit(1);
end
exit(0);
" > "$log_file" 2>&1

exit_code=$?

if [ $exit_code -ne 0 ]; then
  echo "[ERROR] MATLAB DICOM conversion failed for $subj. See log: $log_file"
  exit $exit_code
else
  echo "[SUCCESS] DICOM conversion completed for $subj"
  exit 0
fi