#!/bin/bash

scp \
 /vols/Data/preclinical/Myelin_HJB/Projects/ReTa_Yingshi/T2wReg_N4/MYRD5_1a_BN4def.nii.gz \
flg293@cluster1.bmrc.ox.ac.uk:/gpfs3/well/lerch/users/flg293/ReTa_Myrf/data/input/T2wReg_N4/


scp -r \
 /vols/Data/preclinical/Myelin_HJB/Projects/ReTa_Yingshi/MMORF_data_LA \
flg293@cluster1.bmrc.ox.ac.uk:/gpfs3/well/lerch/users/flg293/ReTa_Myrf/data//

