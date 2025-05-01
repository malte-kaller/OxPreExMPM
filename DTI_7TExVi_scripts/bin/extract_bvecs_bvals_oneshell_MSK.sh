#!/bin/bash

foldername=$1
if [[ ! -f ${foldername}/method_shell1 ]]; then
  echo "Error: method_shell1 not found in $foldername"
  exit 1
fi

echo "[INFO] Extracting bvals..."

# === Step 1: Extract 33 bvals ===
sed -n '/PVM_DwEffBval/,/PVM_DwGradVec/{
  /PVM_DwEffBval/d
  /PVM_DwGradVec/d
  p
}' "${foldername}/method_shell1" \
| tr -s " " "\n" \
| grep -E '^[0-9.]+' > "${foldername}/bvals_original.txt"

mapfile -t bvals < "${foldername}/bvals_original.txt"

# === Step 2: Move 3 lowest bvals to volumes 1, 12, 23 ===
low_bvals=($(printf "%s\n" "${bvals[@]}" | sort -n | head -n 3))
target_pos=(0 11 22)
remaining_bvals=()
found=0

for b in "${bvals[@]}"; do
  if [[ "$found" -lt 3 && " ${low_bvals[*]} " =~ " $b " ]]; then
    ((found++))
    continue
  fi
  remaining_bvals+=("$b")
done

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

printf "%s " "${final_bvals[@]}" > "${foldername}/bvals"
rm "${foldername}/bvals_original.txt"

echo "[INFO] Extracting bvecs..."

# === Step 3: Extract only the 30 real vectors from PVM_DwGradVec ===
vec_block=$(awk '
  f && /^[^#]/ { gsub(/[()]/, ""); print }
  /##\$PVM_DwGradVec=\( 33, 3 \)/ { f=1 }
  f && /^##/ { exit }
' "${foldername}/method_shell1")

readarray -t all_vals <<< "$(echo "$vec_block" | tr -s ' ' '\n' | grep -E '^-?[0-9.]+$')"

if [[ ${#all_vals[@]} -lt 99 ]]; then
  echo "[ERROR] Found only ${#all_vals[@]} gradient values — expected 99"
  exit 1
fi

# Skip first 3 vectors = 9 values
real_vectors=()
for i in $(seq 9 3 98); do
  real_vectors+=("${all_vals[$i]} ${all_vals[$((i+1))]} ${all_vals[$((i+2))]}")
done

# === Step 4: Insert (0 0 0) at volumes 1, 12, 23 ===
insert_zero_indices=(0 11 22)
adjusted_vecs=()
vec_idx=0

for i in $(seq 0 32); do
  if [[ " ${insert_zero_indices[*]} " =~ " $i " ]]; then
    adjusted_vecs+=("0 0 0")
  else
    adjusted_vecs+=("${real_vectors[$vec_idx]}")
    ((vec_idx++))
  fi
done

# === Step 5: Transpose into FSL bvecs format ===
bvecs_x=(); bvecs_y=(); bvecs_z=()

for vec in "${adjusted_vecs[@]}"; do
  read -r x y z <<< "$vec"
  bvecs_x+=("$x")
  bvecs_y+=("$y")
  bvecs_z+=("$z")
done

{
  printf "%s " "${bvecs_x[@]}"
  echo
  printf "%s " "${bvecs_y[@]}"
  echo
  printf "%s " "${bvecs_z[@]}"
  echo
} > "${foldername}/bvecs"

echo "[SUCCESS] Created ${foldername}/bvals and ${foldername}/bvecs (33 entries each)"