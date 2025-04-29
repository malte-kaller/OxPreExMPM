#!/bin/bash
#### extract_bvecs_bvals_oneshell.sh (fixed version)
foldername=$1

# === Extract full bvals block ===
sed -n '/PVM_DwEffBval/,/PVM_DwGradVec/{
  /PVM_DwEffBval/d
  /PVM_DwGradVec/d
  p
}' ${foldername}/method_shell1 \
| tr -s " " "\n" \
| grep -E '^[0-9]+' > ${foldername}/bvals_shell1

cat ${foldername}/bvals_shell1 > ${foldername}/bvals2
cat ${foldername}/bvals2 | tr "\n" " " > ${foldername}/bvals_method
xargs -a ${foldername}/bvals_method -n1 printf "%1.f " > ${foldername}/bvals

# === Extract raw gradient vectors (DWIs only) ===
sed -n '/##\$PVM_DwDir=(/,/##\$PVM_DwDgSwitch/{
  /PVM_DwDir/d
  /##\$PVM_DwDgSwitch/d
  p
}' ${foldername}/method_shell1 \
| tr -s " " "\n" \
| grep -E '^-?[0-9.]+' \
| awk 'ORS=NR%3?" ":"\n"' > ${foldername}/bvecs_dwi_only.txt

# === Dynamically match bvals to bvecs (insert 0 0 0 for b=0 volumes) ===
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

# === Transpose to FSL bvecs format ===
cat ${foldername}/bvecs_shell1 > ${foldername}/bvecs_temp
/vols/Data/km/cetisca/projects/diffpostproc-exvivo-mouse-bruker7t/bin/transpose_bvecs.sh ${foldername}/bvecs_temp >  ${foldername}/bvecs

# === Cleanup ===
rm ${foldername}/bvals_shell1 ${foldername}/bvals2 ${foldername}/bvecs_temp ${foldername}/bvecs_dwi_only.txt ${foldername}/bvals_method