#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

subj="${1:-}"
[[ -n "$subj" ]] || { echo "Usage: $0 <subject_id>"; exit 2; }

# ----------------------- SETUP ------------------------------
CONTAINER=/well/lerch/shared/tools/mice.sif_latest.sif
BIND_PATHS="--bind=/well,/gpfs3"
ctrun(){ singularity exec $BIND_PATHS "$CONTAINER" "$@"; }

# ----------------------- PATHS ------------------------------
IN_DIR="/gpfs3/well/lerch/users/flg293/ReTa_Myrf/data/input/MMORF_data_LA"
OUT_DIR="/gpfs3/well/lerch/users/flg293/ReTa_Myrf/data/output/MBM_trans_applied"
TRANSFORM_DIR="/gpfs3/well/lerch/users/flg293/ReTa_Myrf/reg/T2wReg_N4_250909_All"
CSV_FILE="$TRANSFORM_DIR/analysis.csv"   # needs columns: nlin_file, overall_xfm

INTERP="linear"  # use "nn" for nearest-neighbour (labels), else trilinear

in_dti="$IN_DIR/$subj/DTI"
in_mpm="$IN_DIR/$subj/MPM"
out_dti="$OUT_DIR/$subj/DTI"
out_mpm="$OUT_DIR/$subj/MPM"

echo "[proc][$subj] START"

# ----------------------- NIfTI  MINC ------------------------
convert_folder_to_mnc() {
  local in_dir="$1" out_dir="$2"
  [[ -d "$in_dir" ]] || { echo "[skip][$subj] missing: $in_dir"; return; }
  mkdir -p "$out_dir"

  mapfile -t files < <(find "$in_dir" -maxdepth 1 -type f \( -name "*.nii.gz" -o -name "*.nii" \) | sort)
  [[ ${#files[@]} -eq 0 ]] && { echo "[info][$subj] no NIfTI in $in_dir"; return; }

  for f in "${files[@]}"; do
    local fname base out_mnc tmp_nii
    fname="$(basename "$f")"
    case "$fname" in
      *.nii.gz) base="${fname%.nii.gz}" ;;
      *.nii)    base="${fname%.nii}" ;;
      *)        continue ;;
    esac
    out_mnc="$out_dir/${base}.mnc"
    echo "[convert][$subj] $f -> $out_mnc"
    # ensure overwrite
    rm -f "$out_mnc"
    if [[ "$fname" == *.nii.gz ]]; then
      tmp_nii="$(mktemp "${TMPDIR:-/tmp}/nii2mnc.XXXXXX").nii"
      gunzip -c "$f" > "$tmp_nii"
      ctrun nii2mnc "$tmp_nii" "$out_mnc"
      rm -f "$tmp_nii"
    else
      ctrun nii2mnc "$f" "$out_mnc"
    fi
  done
}

convert_folder_to_mnc "$in_dti" "$out_dti"
convert_folder_to_mnc "$in_mpm" "$out_mpm"

# ----------------------- Resolve LIKE & XFM -------------------
LIKE_IMG=$(awk -F, -v s="$subj" '
  NR==1 {for(i=1;i<=NF;i++) if($i=="nlin_file") c=i; next}
  c && index($c,s)>0 {print $c; exit}
' "$CSV_FILE" || true)
[[ -n "${LIKE_IMG:-}" && "${LIKE_IMG:0:1}" != "/" ]] && LIKE_IMG="$TRANSFORM_DIR/$LIKE_IMG"

XFM_PATH=$(awk -F, -v s="$subj" '
  NR==1 {for(i=1;i<=NF;i++) if($i=="overall_xfm") c=i; next}
  c && index($c,s)>0 {print $c; exit}
' "$CSV_FILE" || true)
[[ -n "${XFM_PATH:-}" && "${XFM_PATH:0:1}" != "/" ]] && XFM_PATH="$TRANSFORM_DIR/$XFM_PATH"

[[ -f "${LIKE_IMG:-/dev/null}" ]] || { echo "[warn][$subj] LIKE_IMG missing: ${LIKE_IMG:-<empty>}"; exit 0; }
[[ -f "${XFM_PATH:-/dev/null}"  ]] || { echo "[warn][$subj] XFM missing: ${XFM_PATH:-<empty>}"; exit 0; }

# ----------------------- Apply Transform + back to NIfTI -----
# interp flag for mincresample
if [[ "$INTERP" == "nn" || "$INTERP" == "nearest" || "$INTERP" == "nearest_neighbour" || "$INTERP" == "nearest_neighbor" ]]; then
  i_flag="-nearest_neighbour"
else
  i_flag="-trilinear"
fi

apply_and_back() {
  local dir="$1"
  [[ -d "$dir" ]] || return
  shopt -s nullglob
  for m in "$dir"/*.mnc; do
    local base out_mnc out_nii out_niigz
    base="${m%.mnc}"
    out_mnc="${base}_nlin.mnc"
    out_nii="${base}_nlin.nii"
    out_niigz="${base}_nlin.nii.gz"

    echo "[xfm][$subj] $m -> $out_mnc"
    # ensure overwrite for outputs
    rm -f "$out_mnc" "$out_nii" "$out_niigz"
    ctrun mincresample -clobber $i_flag -like "$LIKE_IMG" -transform "$XFM_PATH" "$m" "$out_mnc"

    echo "[mnc2nii][$subj] $out_mnc -> $out_niigz"
    ctrun mnc2nii -nii "$out_mnc" "$out_nii"
    gzip -f "$out_nii"
  done
  shopt -u nullglob
}

apply_and_back "$out_dti"
apply_and_back "$out_mpm"

echo "[proc][$subj] DONE"

