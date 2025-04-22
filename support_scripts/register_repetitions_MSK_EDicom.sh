#!/usr/bin/env bash

# === USAGE ===
# register_repetitions_MSK_EDicom.sh <subject> <MTfile> <PDfile> <T1file> <settings_file>

# Load inputs
subj=$1
MTfile=$2
PDfile=$3
T1file=$4
source $5  # project_settings.sh

# Define paths
subDir="$procDIR/$subj/MPM_preprocessing"
outDir="$subDir/SubjectDIR_RepetitionAverage"
mkdir -p "$outDir"

# Define map types
maptype="MT T1 PD"

# === Step 1: Build acquisition order files ===
for map in $maptype; do
  map_var="${map}file"
  pattern=${!map_var}
  acqdir="$scriptDIR/acquisition_order_files/$map"
  acqfile="$acqdir/${map}_${subj}.txt"
  mkdir -p "$acqdir"
  rm -f "$acqfile"
  ls -d "$subDir"/${pattern}* >> "$acqfile"
done

# === Step 2: Process each map type ===
for map in $maptype; do
  echo "[INFO] Processing $map for $subj"
  acqfile="$scriptDIR/acquisition_order_files/$map/${map}_${subj}.txt"
  referenceScan=$(head -n 1 "$acqfile")

  while read -r repetition; do
    echo "[INFO] Processing repetition: $repetition"
    fslmerge -t "$repetition/repetition_sum.nii.gz" "$repetition"/*.nii.gz
    fslmaths "$repetition/repetition_sum.nii.gz" -Tmean "$repetition/repetition_average.nii.gz"
    rm -f "$repetition/repetition_sum.nii.gz"

    flirt -in "$repetition/repetition_average.nii.gz" \
          -ref "$referenceScan/repetition_average.nii.gz" \
          -out "$repetition/repetition_average_registered.nii.gz" \
          -omat "$repetition/repetition_average_transform.mat" \
          -interp spline -dof 6 -searchcost normmi -cost normmi

    for a in {0..7}; do
      echoFile=$(printf "%04d" $a)
      inputFile=$(find "$repetition" -name "MF*_echo_${echoFile}.nii.gz")
      flirt -in "$inputFile" \
            -ref "$referenceScan/repetition_average.nii.gz" \
            -applyxfm -init "$repetition/repetition_average_transform.mat" \
            -out "$repetition/coregistered_echo_$((a+1)).nii.gz" \
            -interp spline
    done
  done < "$acqfile"

  mkdir -p "$outDir/${map}wDIR"
  for a in {0..7}; do
    echoFile=$(printf "%04d" $a)
    srcJson=$(find "$referenceScan" -name "MF*_echo_${echoFile}.json")
    cp "$srcJson" "$outDir/${map}wDIR/${map}W_echo_mean_$((a+1)).json"
  done

done

# === Step 3: Average across repetitions ===
for a in {1..8}; do
  for map in $maptype; do
    echo_files=$(find "$subDir" -type f -name "coregistered_echo_${a}.nii.gz" -path "*/${!map}file*/coregistered_echo_${a}.nii.gz")
    fslmerge -t "$outDir/${map}wDIR/repetition_sum_${a}.nii.gz" $echo_files
    fslmaths "$outDir/${map}wDIR/repetition_sum_${a}.nii.gz" -Tmean "$outDir/${map}wDIR/${map}W_echo_mean_${a}.nii.gz"
    rm -f "$outDir/${map}wDIR/repetition_sum_${a}.nii.gz"
  done
done

# === Step 4: Unzip final .nii.gz files for hMRI ===
echo "[INFO] Unzipping final files for hMRI processing..."
gunzip -f "$outDir"/MTwDIR/*.nii.gz
gunzip -f "$outDir"/PDwDIR/*.nii.gz
gunzip -f "$outDir"/T1wDIR/*.nii.gz

echo "=== SCRIPT DONE ==="
