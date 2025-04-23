#!/bin/bash

module add fsl
source "project_settings.sh"

# Define subject list
subjlist="20250224_084029_MYRD5_1b_MyReach_T2w_DTI_MPM_1_1"

# Orientation correction function
orient_corr () {
  local file="$1"
  echo "[INFO] Reorienting: $file"

  # Delete any existing orientation (safe reset)
  fslorient -deleteorient "$file"

  # Apply axis swap: z -y x
  fslswapdim "$file" z y x "$file"

  # Set new voxel scaling and affine matrix
  fslorient -setsform 0.1 0 0 0  \
                        0 0.1 0 0  \
                        0 0 0.1 0  \
                        0 0 0 1 "$file"

  # Copy to qform and activate both codes
  fslorient -copysform2qform "$file"
  fslorient -setsformcode 1 "$file"
  fslorient -setqformcode 1 "$file"
}

for subj in $subjlist; do
  echo "[INFO] Processing subject: $subj"

 t2scan=$(grep "T2w" "$rawBruDIR/acquisition_order_${subj}.txt" | awk '{print $1}')

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