#!/bin/bash

module add fsl
source "project_settings.sh"

# Define subject list
subjlist="20250224_084029_MYRD5_1b_MyReach_T2w_DTI_MPM_1_1"

# Orientation correction function
orient_corr () {
  input_file="$1"

  echo "[INFO] Reorienting: $input_file"

  # Clear existing orientation info
  fslorient -deleteorient "$input_file"

  # Correct orientation: preserve L/R, flip A/P and S/I
  fslswapdim "$input_file" RL AP SI "$input_file"

  # Set sform and qform codes
  fslorient -copysform2qform "$input_file"
  fslorient -setsformcode 1 "$input_file"
  fslorient -setqformcode 1 "$input_file"

  # Optional: standard reorientation
  fslreorient2std "$input_file" "$input_file"

  echo "[INFO] Reorientation complete."
}

for subj in $subjlist; do
  echo "[INFO] Processing subject: $subj"

  t2scan=$(grep -n "T2w" "$rawBruDIR/acquisition_order_${subj}.txt" | cut -d':' -f1)

  if [ -z "$t2scan" ]; then
    echo "[WARNING] No T2w scan found for $subj"
    continue
  fi

  inputfile=$(ls "$rawBruDIR/$subj/$t2scan/pdata/1/nifti/"*_1.nii 2>/dev/null)
  if [ ! -f "$inputfile" ]; then
    echo "[ERROR] T2w NIfTI file not found for $subj"
    continue
  fi

  outputfolder="$procDIR/$subj/T2w_reorientated"
  mkdir -p "$outputfolder"

  echo "[INFO] Copying T2w file to output folder"
  cp "$inputfile" "$outputfolder/T2w.nii"

  outputfile="$outputfolder/T2w.nii"
  gzip -f "$outputfile"

  orient_corr "${outputfile}.gz"
done

echo "[DONE] All subjects processed."