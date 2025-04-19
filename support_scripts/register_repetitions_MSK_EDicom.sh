#!/usr/bin/env bash

# Load modules
module add fsl
module add fsl_sub

# Get arguments
subj=$1
MTfile=$2
PDfile=$3
T1file=$4
source $5  # project_settings.sh

# Define map types
maptype="MT T1 PD"

# Define input/output paths based on updated structure
subDir="$procDIR/$subj/MPM_preprocessing"
outDir="$subDir/SubjectDIR_RepetitionAverage"
mkdir -p "$outDir"

# === Step 1: Build acquisition order files ===

for map in $maptype; do
  mkdir -p "$scriptDIR/acquisition_order_files/$map"
  outFile="$scriptDIR/acquisition_order_files/${map}/${map}_${subj}.txt"
  rm -f "$outFile"
  
  # List all folders matching the scan type (e.g., MT) into the acquisition order file
  ls -d "$subDir"/${!mapfile}* >> "$outFile"
done

# === Step 2: Loop over each modality ===

for map in $maptype; do
  echo "[INFO] Processing map type: $map"

  mapFile="$scriptDIR/acquisition_order_files/${map}/${map}_${subj}.txt"
  referenceScan=$(head -n 1 "$mapFile")

  while read -r repetition; do
    echo "[INFO] Processing repetition: $repetition"

    # Step 2.1: Average all echoes within a repetition
    fslmerge -t "$repetition/repetition_sum.nii.gz" "$repetition"/*.nii.gz
    fslmaths "$repetition/repetition_sum.nii.gz" -Tmean "$repetition/repetition_average.nii.gz"
    rm -f "$repetition/repetition_sum.nii.gz"

    # Step 2.2: Register to reference scan
    flirt -in "$repetition/repetition_average.nii.gz" \
          -ref "$referenceScan/repetition_average.nii.gz" \
          -out "$repetition/repetition_average_registered.nii.gz" \
          -omat "$repetition/repetition_average_transform.mat" \
          -interp spline -dof 6 -searchcost normmi -cost normmi

    # Step 2.3: Apply transformation to all echo images (assumes 8 echoes)
    for a in {0..7}; do
      echo "[INFO] Registering echo $a"
      echoFile=$(printf "%04d" $a)
      inputFile=$(find "$repetition" -name "MF*_echo_${echoFile}.nii.gz")
      flirt -in "$inputFile" \
            -ref "$referenceScan/repetition_average.nii.gz" \
            -applyxfm -init "$repetition/repetition_average_transform.mat" \
            -out "$repetition/coregistered_echo_$((a+1)).nii.gz" \
            -interp spline
    done
    echo "[INFO] Done with $repetition"
  done < "$mapFile"

  # === Step 3: Copy and rename JSONs from reference scan ===
  mkdir -p "$outDir/${map}wDIR"
  for a in {0..7}; do
    echoFile=$(printf "%04d" $a)
    srcJson=$(find "$referenceScan" -name "MF*_echo_${echoFile}.json")
    destJson="$outDir/${map}wDIR/${map}W_echo_mean_$((a+1)).json"
    cp "$srcJson" "$destJson"
    echo "[INFO] Copied metadata to $destJson"
  done
done

# === Step 4: Average across repetitions for each map and echo ===

for a in {1..8}; do
  echo "[INFO] Averaging echo $a across repetitions"

  for map in MT T1 PD; do
    echo "[INFO] Averaging $map echo $a"
    input_files=$(find "$subDir/${!mapfile}"* -name "coregistered_echo_${a}.nii.gz")
    fslmerge -t "$outDir/${map}wDIR/repetition_sum_${a}.nii.gz" $input_files
    fslmaths "$outDir/${map}wDIR/repetition_sum_${a}.nii.gz" \
             -Tmean "$outDir/${map}wDIR/${map}W_echo_mean_${a}.nii.gz"
    rm -f "$outDir/${map}wDIR/repetition_sum_${a}.nii.gz"
  done
done

# === Step 5: Unzip all .nii.gz files (hMRI requires uncompressed) ===

echo "[INFO] Unzipping final files for hMRI processing..."

gunzip -f "$outDir"/MTwDIR/*.nii.gz
gunzip -f "$outDir"/PDwDIR/*.nii.gz
gunzip -f "$outDir"/T1wDIR/*.nii.gz

echo "=== SCRIPT DONE ==="