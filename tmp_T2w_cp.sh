#!/bin/bash

for f in /vols/Data/preclinical/Myelin_HJB/Projects/ReTa_Yingshi/ReTa_Yingshi_preprocessing/**/T2w_reorientated/*.nii.gz; do
    # get just the filename part
    fname=$(basename "$f")

    # extract the MY...h pattern (from MY up to the first lowercase letter)
    subj=$(echo "$f" | grep -oE 'MY[[:upper:][:digit:]_]*[[:lower:]]')

   
    # copy file into that directory
    cp "$f" "/vols/Data/preclinical/Myelin_HJB/Projects/ReTa_Yingshi/T2wReg_N4/${subj}_T2w.nii.gz"
done
