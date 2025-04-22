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


# === Step 3: Average across repetitions for each map and echo ===

for a in {1..8}; do
  echo "[INFO] Averaging echo $a across repetitions"

  for map in MT T1 PD; do
    echo "[INFO] Averaging $map echo $a"

    mapfile="${map}file"
    pattern="${!mapfile}"

    input_files=$(find "$subDir"/${pattern}* -name "coregistered_echo_${a}.nii.gz")

    if [ -z "$input_files" ]; then
      echo "[WARNING] No input files found for $map echo $a — skipping"
      continue
    fi

    rep_dir="$outDir/${map}wDIR"
    mkdir -p "$rep_dir"

    fslmerge -t "$rep_dir/repetition_sum_${a}.nii.gz" $input_files
    fslmaths "$rep_dir/repetition_sum_${a}.nii.gz" -Tmean "$rep_dir/${map}W_echo_mean_${a}.nii.gz"
    rm -f "$rep_dir/repetition_sum_${a}.nii.gz"
  done
done


# === Step 4: Unzip final .nii.gz files for hMRI ===
echo "[INFO] Unzipping final files for hMRI processing..."
gunzip -f "$outDir"/MTwDIR/*.nii.gz
gunzip -f "$outDir"/PDwDIR/*.nii.gz
gunzip -f "$outDir"/T1wDIR/*.nii.gz

echo "=== SCRIPT DONE ==="
