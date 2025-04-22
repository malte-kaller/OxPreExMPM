#!/bin/bash

# === USAGE ===
# register_repetitions_MSK_EDicom.sh <subject> <MTfile> <PDfile> <T1file> <settings_file>

subj=$1
MTfile=$2
PDfile=$3
T1file=$4
source $5  # project_settings.sh

# Define map types
maptypes="MT T1 PD"

# Define paths
subDir="$procDIR/$subj/MPM_preprocessing"
outDir="${subDir}/SubjectDIR_RepetitionAverage"
mkdir -p "$outDir"

# === Step 1: Build acquisition order files ===

for map in $maptypes; do
  file_var="${map}file"                     # e.g. MTfile, PDfile...
  file_pattern="${!file_var}"              # resolves to value of MTfile
  acqfile="$scriptDIR/acquisition_order_files/$map/${map}_${subj}.txt"

  mkdir -p "$scriptDIR/acquisition_order_files/$map"
  rm -f "$acqfile"
  ls -d "$subDir"/${file_pattern}* >> "$acqfile"
done

# === Step 2: Process each modality ===

for map in $maptypes; do
  echo "[INFO] Processing $map for subject $subj"

  acqfile="$scriptDIR/acquisition_order_files/$map/${map}_${subj}.txt"
  referenceScan=$(head -n 1 "$acqfile")

  while read -r repetition; do
    echo "[INFO] Processing repetition: $repetition"

    # Step 2.1: Average echoes within repetition
    fslmerge -t "$repetition/repetition_sum.nii.gz" "$repetition"/*.nii.gz
    fslmaths "$repetition/repetition_sum.nii.gz" -Tmean "$repetition/repetition_average.nii.gz"
    rm -f "$repetition/repetition_sum.nii.gz"

    # Step 2.2: Register to reference repetition
    flirt -in "$repetition/repetition_average.nii.gz" \
          -ref "$referenceScan/repetition_average.nii.gz" \
          -out "$repetition/repetition_average_registered.nii.gz" \
          -omat "$repetition/repetition_average_transform.mat" \
          -interp spline -dof 6 -searchcost normmi -cost normmi

    # Step 2.3: Apply registration transform to each echo
    for a in {0..7}; do
      echo "Registering echo $((a+1))"
      echoFile=$(printf "%04d" "$a")
      inputFile=$(find "$repetition" -name "*_echo_${echoFile}.nii.gz")
      flirt -in "$inputFile" \
            -ref "$referenceScan/repetition_average.nii.gz" \
            -applyxfm -init "$repetition/repetition_average_transform.mat" \
            -out "$repetition/coregistered_echo_$((a+1)).nii.gz" \
            -interp spline
    done

  done < "$acqfile"

  # Step 2.4: Copy and rename JSON metadata
  mkdir -p "$outDir/${map}wDIR"
  for a in {0..7}; do
    echoFile=$(printf "%04d" "$a")
    srcJson=$(find "$referenceScan" -name "*_echo_${echoFile}.json")
    cp "$srcJson" "$outDir/${map}wDIR/${map}W_echo_mean_$((a+1)).json"
  done
done

# === Step 3: Average across repetitions for each echo ===

for a in {1..8}; do
  echo "[INFO] Averaging repetitions for echo $a"

  for map in MT T1 PD; do
    echo "[INFO] Averaging $map echo $a"

    coreg_echos=$(find "$subDir" -type f -name "${mapfile}*/coregistered_echo_${a}.nii.gz")
    outRep="$outDir/${map}wDIR/repetition_sum_${a}.nii.gz"
    outAvg="$outDir/${map}wDIR/${map}W_echo_mean_${a}.nii.gz"

    fslmerge -t "$outRep" $coreg_echos
    fslmaths "$outRep" -Tmean "$outAvg"
    rm -f "$outRep"
  done
done

echo "[SUCCESS] Register repetitions completed for $subj"