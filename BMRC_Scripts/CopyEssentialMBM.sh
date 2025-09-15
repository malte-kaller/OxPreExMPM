TRANSFORM_DIR="/gpfs3/well/lerch/users/flg293/ReTa_Myrf/reg/T2wReg_N4_250909_All"
PROJ_ROOT="/gpfs3/well/lerch/users/flg293/ReTa_Myrf/data/output/MYRF_ReTa_Project_Registered_Yingshi/MBMRegistration_Essential/T2wReg_N4_250909_All"

mkdir -p "$PROJ_ROOT"

rsync -muvr \
  -f '+ */' \
  -f '+ *log_det*fwhm0.2*.mnc' \
  -f '+ *voted.mnc' \
  -f '+ *nlin-3.mnc' \
  -f '+ analysis.csv' \
  -f '- *' \
  "$TRANSFORM_DIR"/  "$PROJ_ROOT"/

