#!/bin/bash

module add fsl
source "project_settings.sh"

# Define subject list
#subjlist="20250224_084029_MYRD5_1b_MyReach_T2w_DTI_MPM_1_1"

# Orientation correction function
orient_corr () {
  local file="$1"
  echo "[INFO] Reorienting: $file"

  # Delete any existing orientation (safe reset)
  fslorient -deleteorient "$file"

  # Apply axis swap: z -y x
  fslswapdim "$file" z y -x "$file"

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

  inputfile=${procDIR}/$subj/MPM_preprocessing/SubjectDIR_RepetitionAverage/hMRI_Results_B1/Results/PDW_echo_mean_1_MTsat.nii


  outputfolder="$projectDIR/MTsatRegTest/"
  mkdir -p "$outputfolder"

  #!/bin/bash

if [[ $subj =~ (M[A-Z0-9_]+?[0-9][a-z]) ]]; then
    name="${BASH_REMATCH[1]}"
    echo "$result"
else
    echo "No match found"
fi


  echo "[INFO] Copying T2w file to output folder"
  cp "$inputfile" "$outputfolder/${name}_MTsat.nii"

  outputfile="$outputfolder/${name}_MTsat.nii"
  gzip -f "$outputfile"

  orient_corr "${outputfile}.gz"
done

echo "[DONE] All subjects processed."
