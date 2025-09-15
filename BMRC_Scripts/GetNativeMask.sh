
#!/bin/bash

# Define the path to the Singularity container
CONTAINER=/well/lerch/shared/tools/mice.sif_latest.sif
BIND_PATHS="--bind=/well,/gpfs3"

# Define a function to run commands in the Singularity container
run_in_container() {
    singularity exec $BIND_PATHS $CONTAINER "$@"
}

#===Define Working Directory===

workDIR="/gpfs3/well/lerch/users/flg293/ReTa_Myrf/reg/T2wReg_N4_250822_R1"  # <-- change to your folder path
StudyName="T2wReg_N4_250822_R1"  # <-- change to your study name

# Define analysis file path
analysis_file="$workDIR/analysis.csv"

#===Define Subjects===

# Pattern: MY + letters/numbers + _ + number + letter
subjList=$(grep -oE 'MY[A-Za-z0-9]+_[0-9]+[a-z]' "$analysis_file" | sort -u)

echo "Subjects found:"
echo "$subjList"

#===Define the path to the main study mask===
# Overall study mask (workDIR-dependent)
studyMask="${workDIR}/${StudyName}_nlin/${StudyName}-nlin-3_mask.mnc"

# Get column indices once (outside loop is fine)
xfm_col=$(awk -F, 'NR==1{for(i=1;i<=NF;i++) if($i=="overall_xfm"){print i; exit}}' "$analysis_file")
target_col=$(awk -F, 'NR==1{for(i=1;i<=NF;i++) if($i=="native_file"){print i; exit}}' "$analysis_file")

for sub in $subjList; do
  echo "Processing subject: $sub"

# Extract subject-specific transform and native target (avoid awk var name 'sub')
subj_xfm=$(awk -F, -v subj_id="$sub" -v col="$xfm_col" 'NR>1 && index($0, subj_id) {print $col; exit}' "$analysis_file")
subj_target=$(awk -F, -v subj_id="$sub" -v col="$target_col" 'NR>1 && index($0, subj_id) {print $col; exit}' "$analysis_file")


  # Extract subject-specific transform and native target
#  subj_xfm=$(awk -F, -v sub="$sub" -v col="$xfm_col" 'NR>1 && $0 ~ sub {print $col; exit}' "$analysis_file")
 # subj_target=$(awk -F, -v sub="$sub" -v col="$target_col" 'NR>1 && $0 ~ sub {print $col; exit}' "$analysis_file")

  # Define output path for subject-specific mask
  out_mask="${workDIR}/masks/${sub}_mask.mnc"
  mkdir -p "$(dirname "$out_mask")"

  # Apply inverse of subject transform to bring study mask into subject space
  run_in_container mincresample \
    -nearest_neighbour \
    -fillvalue 0 \
    -keep_real_range \
    -invert_transformation \
    -transformation "${workDIR}/$subj_xfm" \
    -like "$subj_target" \
    "$studyMask" "$out_mask"
done


  
