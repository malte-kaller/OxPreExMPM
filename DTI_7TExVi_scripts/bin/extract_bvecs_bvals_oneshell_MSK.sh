#!/bin/bash

foldername=$1
if [[ ! -f ${foldername}/method_shell1 ]]; then
  echo "❌ method_shell1 not found in $foldername"
  exit 1
fi

echo "[INFO] Extracting bvals..."

# Step 1: Extract 33 bvals
sed -n '/PVM_DwEffBval/,/PVM_DwGradVec/{
  /PVM_DwEffBval/d
  /PVM_DwGradVec/d
  p
}' "${foldername}/method_shell1" \
| tr -s " " "\n" \
| grep -E '^[0-9.]+' > "${foldername}/bvals_original.txt"

mapfile -t bvals < "${foldername}/bvals_original.txt"

# Step 2: Move lowest 3 bvals to volumes 1, 12, 23
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

# Step 3: Extract 33 gradient vectors (confirmed good method)
sed -n '/##\$PVM_DwGradVec=( 33, 3 )/,/^##/p' "${foldername}/method_shell1" \
| tr -s " " "\n" \
| grep -E '^-?[0-9.]+' \
| head -n 99 \
| awk 'ORS=NR%3?" ":"\n"' > "${foldername}/bvecs_all.txt"

mapfile -t raw_vecs < "${foldername}/bvecs_all.txt"

if [[ ${#raw_vecs[@]} -ne 33 ]]; then
  echo "❌ bvecs_all.txt contains ${#raw_vecs[@]} vectors — expected 33"
  exit 1
fi

# Step 4: Override only Volumes 1, 12, 23 with (0 0 0)
insert_zero_indices=(0 11 22)
for idx in "${insert_zero_indices[@]}"; do
  raw_vecs[$idx]="0 0 0"
done

# Step 5: Transpose to 3-row FSL format
bvecs_x=(); bvecs_y=(); bvecs_z=()

for vec in "${raw_vecs[@]}"; do
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

rm "${foldername}/bvecs_all.txt"

echo "[SUCCESS] ✅ Files created:"
echo "         ${foldername}/bvals"
echo "         ${foldername}/bvecs"