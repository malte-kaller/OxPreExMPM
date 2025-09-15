#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

module add fsl

# Paths (same as your main setup)
IN_DIR="/gpfs3/well/lerch/users/flg293/ReTa_Myrf/data/input/MMORF_data_LA"

# Location of the per-subject job script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOB_SCRIPT="$SCRIPT_DIR/ApplyMBM.sh"

LOGDIR="$SCRIPT_DIR/logs_convert"
mkdir -p "$LOGDIR"

# Build subject list as an ARRAY (newline-separated  robust against IFS)
#mapfile -t subjects < <(find "$IN_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)

SubjectLIST=$(find "$IN_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | paste -sd ' ' -)
echo "$SubjectLIST"

# (optional) test with first two only
#SubjectLIST=("${SubjectLIST:0:2}")
#SubjectLIST=$(printf '%s' "$SubjectLIST" | tr ' ' '\n' | head -n 2 | paste -sd ' ' -)
#echo "$SubjectLIST"


#echo "[info] Submitting ${#subjects[@]} subjects: ${subjects[*]}"

# One job per subject  iterates strictly one-by-one
IFS=' ' read -r -a subjects <<< "$SubjectLIST"
for subj in "${subjects[@]}"; do
  fsl_sub -l "$LOGDIR" -N "proc_${subj}" bash "$JOB_SCRIPT" "$subj"
done


echo "[done] Submitted ${SubjectLIST} jobs."

