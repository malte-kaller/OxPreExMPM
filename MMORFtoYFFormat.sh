#!/bin/bash

#This script takes the data from the MMORF registration and sorts it into folders like before

#Step by step, what needs to be done: 

#SETUP: All required mdoules 

module add fsl
source "project_settings.sh"

#Define key directories
inputDIR=/vols/Scratch/flange/for_malte/mmorf_MYRF_ReTa/template/nln_step_05/iteration_01
outDIR=$projectDIR/MMORF_Registrated_data

# Getting all subjects ready =====
  ## Make a list of all subjects exacted from the folder

  # produce a newline-separated unique list of subject IDs
subjects=$(
  find "$inputDIR" -maxdepth 1 -type f -name '*.nii.gz' -printf '%f\n' \
  | sed -E 's/.*((MYR[A-Za-z])[0-9]{1,2}_[0-9][a-z](_flipped)?).*/\1/' \
  | grep '^MYR' \
  | sort -u \
  | tr '\n' ' '
)

for id in $subjects; do
    echo "subject: $id"
done

# =====
  
# Create subject specific folders =====
for id in $subjects; do
  mkdir -p "$outDIR/$id"

# =====

# COPY OVER ALL REQUIRED MODALITIES 

 ## T2w images (01)

   # ----- T2w (scalar_mod_01_brain_to_template) -----
  if [[ -f "$inputDIR/${id}_scalar_mod_01_brain_to_template.nii.gz" ]]; then
    cp "$inputDIR/${id}_scalar_mod_01_brain_to_template.nii.gz" \
       "$outDIR/$id/${id}_T2w.nii.gz"
  elif [[ -f "$inputDIR/${id}_flipped_scalar_mod_01_brain_to_template.nii.gz" ]]; then
    cp "$inputDIR/${id}_flipped_scalar_mod_01_brain_to_template.nii.gz" \
       "$outDIR/$id/${id}_T2w.nii.gz"
  else
    echo "Missing T2w for $id"
  fi

 ## MTsat images (02)

   # ----- MTsat (scalar_mod_02_brain_to_template) -----
  if [[ -f "$inputDIR/${id}_scalar_mod_02_brain_to_template.nii.gz" ]]; then
    cp "$inputDIR/${id}_scalar_mod_02_brain_to_template.nii.gz" \
       "$outDIR/$id/${id}_MTsat.nii.gz"
  elif [[ -f "$inputDIR/${id}_flipped_scalar_mod_02_brain_to_template.nii.gz" ]]; then
    cp "$inputDIR/${id}_flipped_scalar_mod_02_brain_to_template.nii.gz" \
       "$outDIR/$id/${id}_MTsat.nii.gz"
  else
    echo "Missing MTsat for $id"
  fi

 ## DTI images (Tensor_MOD_01)

   # ----- DTI (tensor_mod_01_to_template) -----
  if [[ -f "$inputDIR/${id}_tensor_mod_01_to_template.nii.gz" ]]; then
    cp "$inputDIR/${id}_tensor_mod_01_to_template.nii.gz" \
       "$outDIR/$id/${id}_DTI.nii.gz"
  elif [[ -f "$inputDIR/${id}_flipped_tensor_mod_01_to_template.nii.gz" ]]; then
    cp "$inputDIR/${id}_flipped_tensor_mod_01_to_template.nii.gz" \
       "$outDIR/$id/${id}_DTI.nii.gz"
  else
    echo "Missing DTI for $id"
  fi

done

# Process the DTI 

for id in $subjects; do
  dti="$outDIR/$id/${id}_DTI.nii.gz"

  if [[ -f "$dti" ]]; then
    fslmaths "$dti" -tensor_decomp "$outDIR/$id/${id}_DTI_decomp"
  else
    echo "No DTI file for $id"
  fi
done

# Calculate RD and AD from the DTI decomposition
for id in $subjects; do

# inside your subject loop, where id is e.g. MYRF31_1g and outDIR is set
L1="$outDIR/$id/${id}_DTI_decomp_L1.nii.gz"
L2="$outDIR/$id/${id}_DTI_decomp_L2.nii.gz"
L3="$outDIR/$id/${id}_DTI_decomp_L3.nii.gz"

# AD = L1 (just copy via fslmaths to keep header/format consistent)
if [[ -f "$L1" ]]; then
  fslmaths "$L1" -mul 1 "$outDIR/$id/${id}_AD.nii.gz"
else
  echo "Missing L1 for $id"
fi

# RD = (L2 + L3) / 2
if [[ -f "$L2" && -f "$L3" ]]; then
  fslmaths "$L2" -add "$L3" -div 2 "$outDIR/$id/${id}_RD.nii.gz"
else
  echo "Missing L2/L3 for $id"
fi

done