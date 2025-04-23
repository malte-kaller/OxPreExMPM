#!/bin/bash

module add fsl
source "project_settings.sh"

# Define subject list
subjlist="20250224_084029_MYRD5_1b_MyReach_T2w_DTI_MPM_1_1"

for subj in $subjlist; do
  echo "[INFO] Processing subject: $subj"

  t2scan=$(grep -n "T2w" "$rawBruDIR/acquisition_order_${subj}.txt" | cut -d':' -f1)

  if [ -z "$t2scan" ]; then
    echo "[WARNING] No T2w scan found for $subj"
    continue
  fi

  inputfile="$rawBruDIR/$subj/$t2scan/pdata/1/nifti/"*_1.nii
  outputfolder="$procDIR/$subj/T2w_reorientated"
  mkdir -p "$outputfolder"

  echo "[INFO] Copying T2w file to output folder"
  cp "$inputfile" "$outputfolder/T2w.nii"

  outputfile="$outputfolder/T2w.nii"
  gzip -f "$outputfile"

  orient_corr () {
    fslorient -deleteorient "$1"
    fslswapdim "$1" z -y x "$1"
    fslorient -setsform 0.1 0 0 0 0 0.1 0 0 0 0 0.1 0 0 0 0 1 "$1"
    fslorient -copysform2qform "$1"
    fslorient -setsformcode 1 "$1"
    fslorient -setqformcode 1 "$1"
  }

  orient_corr "${outputfile}.gz"
done

echo "[DONE] All subjects processed."
