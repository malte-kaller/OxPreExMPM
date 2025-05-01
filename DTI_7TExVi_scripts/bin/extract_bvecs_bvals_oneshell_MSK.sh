#!/bin/bash

# Input: $1 = folder containing method_shell1
foldername=$1

# === Step 1: Extract 33 bvals from method_shell1 ===
sed -n '/PVM_DwEffBval/,/PVM_DwGradVec/{
  /PVM_DwEffBval/d
  /PVM_DwGradVec/d
  p
}' ${foldername}/method_shell1 \
| tr -s " " "\n" \
| grep -E '^[0-9.]+' > ${foldername}/bvals_original.txt

# === Step 2: Move 3 lowest bvals to positions 1, 12, 23 ===
mapfile -t bvals < ${foldername}/bvals_original.txt
low_bvals=($(printf "%s\n" "${bvals[@]}" | sort -n | head -n 3))
target_pos=(0 11 22)  # 0-based indices for volumes 1, 12, 23

# Remove those values from their original positions (once each)
remaining_bvals=()
found=0
for b in "${bvals[@]}"; do
  if [[ "$found" -lt 3 && " ${low_bvals[*]} " =~ " $b " ]]; then
    ((found++))
    continue
  fi
  remaining_bvals+=("$b")
done

# Reconstruct final bvals array
final_bvals=()
lb_i=0
rb_i=0
for i in $(seq 0 32); do
  if [[ " ${target_pos[*]} " =~ " $i " ]]; then
    final_bvals+=("${low_bvals[$lb_i]}")
    ((lb_i++))
  else
    final_bvals+=("${remaining_bvals[$rb_i]}")
    ((rb_i++))
  fi
done

# Save to final bvals file
printf "%s " "${final_bvals[@]}" > ${foldername}/bvals

# === Step 3: Extract 33 bvecs from PVM_DwGradVec ===
sed -n '/##\$PVM_DwGradVec=( 33, 3 )/,/^##\\$/p' ${foldername}/method_shell1 \
| grep -E '^-?[0-9.]+' \
| awk 'ORS=NR%3?" ":"\n"' > ${foldername}/bvecs_all.txt  # 33 X Y Z lines

# === Step 4: Transpose to 3-row FSL format ===
awk '{print $1}' ${foldername}/bvecs_all.txt | paste -sd ' ' - > ${foldername}/bvecs_x
awk '{print $2}' ${foldername}/bvecs_all.txt | paste -sd ' ' - > ${foldername}/bvecs_y
awk '{print $3}' ${foldername}/bvecs_all.txt | paste -sd ' ' - > ${foldername}/bvecs_z

# === Step 5: Zero out b=0 vector columns (positions 1, 12, 23) ===
insert_indices=(0 11 22)
bvecs_out=${foldername}/bvecs
rm -f $bvecs_out

for file in ${foldername}/bvecs_x ${foldername}/bvecs_y ${foldername}/bvecs_z; do
  read -a row < $file
  new_row=()
  for i in $(seq 0 ${#row[@]}); do
    if [[ " ${insert_indices[*]} " =~ " $i " ]]; then
      new_row+=("0")
    fi
    if [[ $i -lt ${#row[@]} ]]; then
      new_row+=("${row[$i]}")
    fi
  done
  printf "%s " "${new_row[@]}" >> $bvecs_out
  echo "" >> $bvecs_out
done

# === Step 6: Cleanup ===
rm ${foldername}/bvals_original.txt ${foldername}/bvecs_all.txt \
   ${foldername}/bvecs_x ${foldername}/bvecs_y ${foldername}/bvecs_z