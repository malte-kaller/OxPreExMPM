#!/bin/bash

# === Input ===
foldername=$1

# === Step 1: Extract all bvals from method file ===
sed -n '/PVM_DwEffBval/,/PVM_DwGradVec/{
  /PVM_DwEffBval/d
  /PVM_DwGradVec/d
  p
}' ${foldername}/method_shell1 \
| tr -s " " "\n" \
| grep -E '^[0-9.]+' > ${foldername}/bvals_shell1_raw

# === Step 2: Reassign lowest 3 bvals to positions 1, 12, 23 ===
mapfile -t all_bvals < ${foldername}/bvals_shell1_raw

# Get the 3 lowest bvals
low_bvals=($(printf "%s\n" "${all_bvals[@]}" | sort -n | head -n 3))
low_i=0
corrected_bvals=()

for i in $(seq 1 33); do
  if [[ "$i" == "1" || "$i" == "12" || "$i" == "23" ]]; then
    corrected_bvals+=("${low_bvals[$low_i]}")
    ((low_i++))
  else
    for b in "${all_bvals[@]}"; do
      if [[ ! " ${low_bvals[*]} " =~ " $b " ]]; then
        corrected_bvals+=("$b")
        all_bvals=("${all_bvals[@]/$b}")
        break
      fi
    done
  fi
done

# Save to FSL-style bvals (1 line, space-separated)
printf "%s " "${corrected_bvals[@]}" > ${foldername}/bvals

# === Step 3: Extract raw bvecs (30 vectors) ===
sed -n '/##\$PVM_DwDir=(/,/##\$PVM_DwDgSwitch/{
  /PVM_DwDir/d
  /##\$PVM_DwDgSwitch/d
  p
}' ${foldername}/method_shell1 \
| tr -s " " "\n" \
| grep -E '^-?[0-9.]+' \
| awk 'ORS=NR%3?" ":"\n"' > ${foldername}/bvecs_shell1_raw  # 30 lines, one X Y Z per line

# === Step 4: Transpose to FSL 3-row format ===
# (Rows: Xs, Ys, Zs)
awk '{print $1}' ${foldername}/bvecs_shell1_raw | paste -sd ' ' - > ${foldername}/bvecs_x
awk '{print $2}' ${foldername}/bvecs_shell1_raw | paste -sd ' ' - > ${foldername}/bvecs_y
awk '{print $3}' ${foldername}/bvecs_shell1_raw | paste -sd ' ' - > ${foldername}/bvecs_z
cat ${foldername}/bvecs_x ${foldername}/bvecs_y ${foldername}/bvecs_z > ${foldername}/bvecs_shell1

# === Step 5: Insert 0s at columns 1, 12, 23 in all three rows ===
bvecs_out=${foldername}/bvecs_fixed
rm -f $bvecs_out

insert_pos=(0 11 22)  # 0-based indices for volumes 1,12,23

while read -r line; do
  read -a vals <<< "$line"
  new_row=()
  for i in $(seq 0 ${#vals[@]}); do
    if [[ " ${insert_pos[*]} " =~ " $i " ]]; then
      new_row+=("0")
    fi
    if [[ $i -lt ${#vals[@]} ]]; then
      new_row+=("${vals[$i]}")
    fi
  done
  printf "%s " "${new_row[@]}" >> $bvecs_out
  echo "" >> $bvecs_out
done < ${foldername}/bvecs_shell1

# Final bvecs file in correct format
cp ${bvecs_out} ${foldername}/bvecs

# === Cleanup ===
rm ${foldername}/bvals_shell1_raw ${foldername}/bvecs_shell1_raw \
   ${foldername}/bvecs_shell1 ${foldername}/bvecs_x ${foldername}/bvecs_y \
   ${foldername}/bvecs_z ${bvecs_out}