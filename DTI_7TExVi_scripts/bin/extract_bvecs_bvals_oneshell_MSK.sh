#### bvals
foldername=$1

# === Extract bvals ===
grep -A8 PVM_DwEffBval= ${foldername}/method_shell1 | tail -n+2 | tr " " "\n" | sed '/^[[:space:]]*$/d' > ${foldername}/bvals_shell1_raw

# Sort bvals and extract the 3 lowest values
low_bvals=$(sort -n ${foldername}/bvals_shell1_raw | head -n 3)

# Create the corrected bvals file with 3 lowest values at positions 1, 12, and 23
corrected_bvals=()
low_bvals_array=($low_bvals)
low_index=0
for i in $(seq 1 33); do
  if [[ "$i" == "1" || "$i" == "12" || "$i" == "23" ]]; then
    corrected_bvals+=("${low_bvals_array[$low_index]}")
    ((low_index++))
  else
    corrected_bvals+=("$(sed -n "${i}p" ${foldername}/bvals_shell1_raw)")
  fi
done

# Save corrected bvals to file
printf "%s " "${corrected_bvals[@]}" > ${foldername}/bvals


# === Extract bvecs ===
sed -n '/##\$PVM_DwDir=(/,/##\$PVM_DwDgSwitch/{ /PVM_DwDir/d; /##\$PVM_DwDgSwitch/d; p }' ${foldername}/method_shell1 \
  | tr " " "\n" | sed '/^[[:space:]]*$/d' | tr -d " \t\r" | tr "\n" " " \
  | sed -e "s/\([^\ ]*\ [^\ ]*\ [^\ ]*\)\ /\1\\`echo -e '\n\r'`/g" | tr "\r" "\n" | sed '/^[[:space:]]*$/d' > ${foldername}/bvecs_shell1_raw

# Insert 0 vectors at positions 1, 12, and 23
bvecs_out=${foldername}/bvecs_shell1
rm -f $bvecs_out

insert_pos=(1 12 23)  # 1-based indices for volumes 1, 12, 23
line_num=1
while read -r line; do
  if [[ " ${insert_pos[*]} " =~ " $line_num " ]]; then
    echo "0 0 0" >> $bvecs_out  # Insert 0 vector
  fi
  echo "$line" >> $bvecs_out
  ((line_num++))
done < ${foldername}/bvecs_shell1_raw

# Transpose bvecs to FSL 3-row format
/vols/Data/km/cetisca/projects/diffpostproc-exvivo-mouse-bruker7t/bin/transpose_bvecs.sh ${foldername}/bvecs_shell1 > ${foldername}/bvecs

# === Cleanup ===
rm ${foldername}/bvals_shell1_raw ${foldername}/bvecs_shell1_raw ${foldername}/bvecs_shell1