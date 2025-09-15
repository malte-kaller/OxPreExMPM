#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------
# Organize registered data into a project folder (ALL subjects)
# Creates:
#   <PROJ_ROOT>/
#     subjects.csv                  # all subjects (ls order), one per row
#     Atlas/                        # + .nii.gz copies
#     Study_Average/                # + .nii.gz copy
#     <subj>/
#       T2w/  MPM/  DTI/  Mask/  jac_det/  transform/
# Copies Jacobians from analysis.csv:
#   - log_nlin_det
#   - log_full_det
# For every copied .mnc (T2w, Mask, jac_det, Atlas, Study_Average) also writes a .nii.gz via mnc2nii -nii.
# ------------------------------------------------------------

# ---------- Config ----------
SRC_OUT_DIR="/gpfs3/well/lerch/users/flg293/ReTa_Myrf/data/output/MBM_trans_applied"
TRANSFORM_DIR="/gpfs3/well/lerch/users/flg293/ReTa_Myrf/reg/T2wReg_N4_250909_All"
CSV_FILE="$TRANSFORM_DIR/analysis.csv"
PROJ_ROOT="/gpfs3/well/lerch/users/flg293/ReTa_Myrf/data/output/MYRF_ReTa_Project_Registered_Yingshi"

# Container (for mnc2nii)
CONTAINER=/well/lerch/shared/tools/mice.sif_latest.sif
BIND_PATHS="--bind=/well,/gpfs3"
ctrun(){ singularity exec $BIND_PATHS "$CONTAINER" "$@"; }

# ---------- Setup ----------
mkdir -p "$PROJ_ROOT/Atlas" "$PROJ_ROOT/Study_Average"

# ---------- subjects.csv (ALL subjects in ls order) ----------
tmp_all_subjects=$(mktemp)
ls -1 -d "$SRC_OUT_DIR"/*/ 2>/dev/null | xargs -n1 basename > "$tmp_all_subjects" || true
{
  echo "subject"
  cat "$tmp_all_subjects"
} > "$PROJ_ROOT/subjects.csv"
echo "[info] Wrote subject list to $PROJ_ROOT/subjects.csv"

# Use ALL subjects
subjects_file="$tmp_all_subjects"

# Helper: convert a single .mnc to .nii.gz next to it
mnc_to_niigz() {
  local mnc="$1"
  [[ -f "$mnc" ]] || return 0
  local base="${mnc%.mnc}"
  local nii="${base}.nii"
  local niigz="${base}.nii.gz"
  rm -f "$nii" "$niigz"
  ctrun mnc2nii -nii "$mnc" "$nii"
  gzip -f "$nii"
}

# ---------- Subject loop (ALL; newline-driven) ----------
while IFS= read -r subj; do
  [ -z "$subj" ] && continue
  echo "[subject] $subj"

  subj_root="$PROJ_ROOT/$subj"
  mkdir -p "$subj_root"/{T2w,MPM,DTI,Mask,jac_det,transform}

  # DTI / MPM (copy *_nlin.nii.gz)  already nii.gz
  dti_src_dir="$SRC_OUT_DIR/$subj/DTI"
  mpm_src_dir="$SRC_OUT_DIR/$subj/MPM"

  shopt -s nullglob
  for f in "$dti_src_dir"/*_nlin.nii.gz; do
    [[ -e "$f" ]] || break
    echo "[copy] DTI: $(basename "$f")"
    cp -f "$f" "$subj_root/DTI/"
  done
  for f in "$mpm_src_dir"/*_nlin.nii.gz; do
    [[ -e "$f" ]] || break
    echo "[copy] MPM: $(basename "$f")"
    cp -f "$f" "$subj_root/MPM/"
  done
  shopt -u nullglob

  # --- CSV lookups (absolute or relative to TRANSFORM_DIR) ---
  t2w_rel=$(awk -F, -v s="$subj" 'NR==1{for(i=1;i<=NF;i++) if($i=="nlin_file") c=i;       next} c && index($c,s)>0 {print $c; exit}' "$CSV_FILE" || true)
  mask_rel=$(awk -F, -v s="$subj" 'NR==1{for(i=1;i<=NF;i++) if($i=="nlin_mask_file") c=i;  next} c && index($c,s)>0 {print $c; exit}' "$CSV_FILE" || true)
  j_nlin_rel=$(awk -F, -v s="$subj" 'NR==1{for(i=1;i<=NF;i++) if($i=="log_nlin_det") c=i;  next} c && index($c,s)>0 {print $c; exit}' "$CSV_FILE" || true)
  j_full_rel=$(awk -F, -v s="$subj" 'NR==1{for(i=1;i<=NF;i++) if($i=="log_full_det") c=i;  next} c && index($c,s)>0 {print $c; exit}' "$CSV_FILE" || true)
  xfm_rel=$(awk      -F, -v s="$subj" 'NR==1{for(i=1;i<=NF;i++) if($i=="overall_xfm") c=i;  next} c && index($c,s)>0 {print $c; exit}' "$CSV_FILE" || true)

  # --- Make absolute paths from CSV (prefix TRANSFORM_DIR when relative) ---
  if [[ -n "$t2w_rel" ]]; then
    if [[ "${t2w_rel:0:1}" != "/" ]]; then t2w_path="$TRANSFORM_DIR/$t2w_rel"; else t2w_path="$t2w_rel"; fi
  else
    t2w_path=""
  fi

  if [[ -n "$mask_rel" ]]; then
    if [[ "${mask_rel:0:1}" != "/" ]]; then mask_path="$TRANSFORM_DIR/$mask_rel"; else mask_path="$mask_rel"; fi
  else
    mask_path=""
  fi

  if [[ -n "$j_nlin_rel" ]]; then
    if [[ "${j_nlin_rel:0:1}" != "/" ]]; then j_nlin_path="$TRANSFORM_DIR/$j_nlin_rel"; else j_nlin_path="$j_nlin_rel"; fi
  else
    j_nlin_path=""
  fi

  if [[ -n "$j_full_rel" ]]; then
    if [[ "${j_full_rel:0:1}" != "/" ]]; then j_full_path="$TRANSFORM_DIR/$j_full_rel"; else j_full_path="$j_full_rel"; fi
  else
    j_full_path=""
  fi

  if [[ -n "$xfm_rel" ]]; then
    if [[ "${xfm_rel:0:1}" != "/" ]]; then xfm_path="$TRANSFORM_DIR/$xfm_rel"; else xfm_path="$xfm_rel"; fi
  else
    xfm_path=""
  fi

  # T2w copy (+ .nii.gz if .mnc)
  if [[ -f "${t2w_path:-/dev/null}" ]]; then
    echo "[copy] T2w: $(basename "$t2w_path")"
    cp -f "$t2w_path" "$subj_root/T2w/"
    [[ "$t2w_path" == *.mnc ]] && mnc_to_niigz "$subj_root/T2w/$(basename "$t2w_path")"
  else
    echo "[warn] T2w not found for $subj (CSV nlin_file: $t2w_rel)"
  fi

  # Mask copy (+ .nii.gz if .mnc)
  if [[ -f "${mask_path:-/dev/null}" ]]; then
    echo "[copy] Mask: $(basename "$mask_path")"
    cp -f "$mask_path" "$subj_root/Mask/"
    [[ "$mask_path" == *.mnc ]] && mnc_to_niigz "$subj_root/Mask/$(basename "$mask_path")"
  else
    echo "[warn] Mask not found for $subj (CSV nlin_mask_file: $mask_rel)"
  fi

  # Jacobians  jac_det/ (log_nlin_det + log_full_det; + .nii.gz if .mnc)
  copy_jac() {
    local src="$1" label="$2"
    if [[ -f "${src:-/dev/null}" ]]; then
      echo "[copy] Jac ($label): $(basename "$src")"
      cp -f "$src" "$subj_root/jac_det/"
      [[ "$src" == *.mnc ]] && mnc_to_niigz "$subj_root/jac_det/$(basename "$src")"
    else
      echo "[warn] $label not found for $subj"
    fi
  }
  copy_jac "$j_nlin_path" "log_nlin_det"
  copy_jac "$j_full_path" "log_full_det"

  # Subject-specific transform (overall_xfm)  transform/  (no image conversion)
  if [[ -f "${xfm_path:-/dev/null}" ]]; then
    echo "[copy] Transform: $(basename "$xfm_path")"
    cp -f "$xfm_path" "$subj_root/transform/"
  else
    echo "[warn] overall_xfm not found for $subj (CSV: $xfm_rel)"
  fi

done < "$subjects_file"
rm -f "$subjects_file"

# ---------- Atlas & Study_Average (copy + .nii.gz) ----------
atlas_dir="$TRANSFORM_DIR/T2wReg_N4_250909_All_nlin/T2wReg_N4_250909_All-nlin-3"

shopt -s nullglob
for f in "$atlas_dir"/*voted.mnc; do
  echo "[copy][Atlas] $(basename "$f")"
  cp -f "$f" "$PROJ_ROOT/Atlas/"
  mnc_to_niigz "$PROJ_ROOT/Atlas/$(basename "$f")"
done
shopt -u nullglob

study_avg="$TRANSFORM_DIR/T2wReg_N4_250909_All_nlin/T2wReg_N4_250909_All-nlin-3.mnc"
if [[ -f "$study_avg" ]]; then
  echo "[copy][Study_Average] $(basename "$study_avg")"
  cp -f "$study_avg" "$PROJ_ROOT/Study_Average/"
  mnc_to_niigz "$PROJ_ROOT/Study_Average/$(basename "$study_avg")"
else
  echo "[warn] Study average not found: $study_avg"
fi

echo "[done] Organized project (ALL subjects) at: $PROJ_ROOT"

