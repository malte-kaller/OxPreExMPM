#!/bin/bash

module add fsl
source "project_settings.sh"

# Define subject list
subjlist="20250611_194551_MYRD8_2a_MyReach_T2w_DTI_MPM_1_1
20250612_192313_MYRD8_2b_MyReach_T2w_DTI_MPM_1_1
20250614_202055_MYRD8_2e_MyReach_T2w_DTI_MPM_1_1
20250615_105715_MYRD8_2f_MyReach_T2w_DTI_MPM_1_1
20250623_192916_MYRD13_1a_MyReach_T2w_DTI_MPM_1_1
20250624_200543_MYRD13_1b_MyReach_T2w_DTI_MPM_1_1
20250625_194802_MYRD13_1d_MyReach_T2w_DTI_MPM_1_1
20250626_194932_MYRD13_1f_MyReach_T2w_DTI_MPM_1_1
20250627_081621_MYRD13_1g_MyReach_T2w_DTI_MPM_1_1
20250627_195007_MYRD13_1c_MyReach_T2w_DTI_MPM_1_1
20250628_081404_MYRD8_2d_MyReach_T2w_DTI_MPM_1_2
20250628_194600_MYRF30_1h_MyReach_T2w_DTI_MPM_2_1_2
20250629_080433_MYRF29_1f_MyReach_T2w_DTI_MPM_2_1_2
20250629_193904_MYRF31_1g_MyReach_T2w_DTI_MPM_2_1_2"

# Orientation correction function
orient_corr () {
  local file="$1"
  echo "[INFO] Reorienting: $file"

  # Delete any existing orientation (safe reset)
  fslorient -deleteorient "$file"

  # Apply axis swap: z -y x
  fslswapdim "$file" -z -y -x "$file"

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