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
  subjects=$(ls *.nii.gz 2>/dev/null \
    | sed -E 's/.*([A-Za-z]{4}[0-9]{1,2}_[0-9][a-z]).*/\1/' \
    | sort -u)

  # loop
  for id in $subjects; do
    echo "subject: $id"

    # get all files matching this subject, flipped or not    
    files=$(ls ${id}*.nii.gz 2>/dev/null)

    echo "Files:"
    echo "$files"
    echo ""
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
