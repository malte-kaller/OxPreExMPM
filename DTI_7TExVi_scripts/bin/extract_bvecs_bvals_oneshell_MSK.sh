#!/bin/bash

# Input: $1 = folder containing method_shell1
foldername=$1

# === 1. Extract all bvals from method_shell1 ===
sed -n '/PVM_DwEffBval/,/PVM_DwGradVec/{
  /PVM_DwEffBval/d
  /PVM_DwGradVec/d
  p
}' ${foldername}/method_shell1 \
| tr -s " " "\n" \
| grep -E '^[0-9.]+' > ${foldername}/bvals_shell1

# Make FSL-style bvals: 1 line, space-separated
cat ${foldername}/bvals_shell1 | tr '\n' ' ' > ${foldername}/bvals

# === 2. Extract raw DWI vectors (gradients) ===
sed -n '/##\\$PVM_DwDir=(/,/##\\$PVM_DwDgSwitch/{
  /PVM_DwDir/d
  /##\\$PVM_DwDgSwitch/d
  p
}' ${foldername}/method_shell1 \
| tr -s " " "\n" \
| grep -E '^-?[0-9.]+' \
| awk 'ORS=NR%3?" ":"\n"' > ${foldername}/bvecs_dwi_only.txt

# === 3. Dynamically build bvecs based on bvals ===
bvecs_out=${foldername}/bvecs_shell1
rm -f $bvecs_out

mapfile -t dwi_vecs < ${foldername}/bvecs_dwi_only.txt
dwi_i=0

for b in $(cat ${foldername}/bvals_shell1); do
  if (( $(echo "$b <= 50" | bc -l) )); then
    echo "0 0 0" >> $bvecs_out
  else
    echo "${dwi_vecs[$dwi_i]}" >> $bvecs_out
    ((dwi_i++))
  fi
done

# === 4. Transpose bvecs to FSL format ===
cat ${foldername}/bvecs_shell1 > ${foldername}/bvecs_temp
/vols/Data/km/cetisca/projects/diffpostproc-exvivo-mouse-bruker7t/bin/transpose_bvecs.sh ${foldername}/bvecs_temp > ${foldername}/bvecs

# === 5. Cleanup ===
rm ${foldername}/bvals_shell1 ${foldername}/bvecs_temp ${foldername}/bvecs_dwi_only.txt