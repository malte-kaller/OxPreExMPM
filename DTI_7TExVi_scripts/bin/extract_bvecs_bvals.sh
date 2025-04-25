#### bvals
foldername=$1

grep -A8 PVM_DwEffBval= ${foldername}/method_shell1 | tail -n+2 | tr " " "\n" | sed '/^[[:space:]]*$/d' | sed -n '2{h; d}; 17{p; x;}; p' | tr -d " \t\r" > ${foldername}/bvals_b2.5k
sed -n '/PVM_DwEffBval/,/PVM_DwGradVec/{ /PVM_DwEffBval/d; /PVM_DwGradVec/d; p }' ${foldername}/method_shell1 | tr " " "\n" | sed '/^[[:space:]]*$/d' | sed -n '2{h; d}; 17{p; x;}; p' | tr -d " \t\r"  > ${foldername}/bvals_b2.5k

grep -A8 PVM_DwEffBval= ${foldername}/method_shell2 | tail -n+2 | tr " " "\n" | sed '/^[[:space:]]*$/d' | sed -n '2{h; d}; 17{p; x;}; p' | tr -d " \t\r"  > ${foldername}/bvals_b10k
sed -n '/PVM_DwEffBval/,/PVM_DwGradVec/{ /PVM_DwEffBval/d; /PVM_DwGradVec/d; p }' ${foldername}/method_shell2 | tr " " "\n" | sed '/^[[:space:]]*$/d' | sed -n '2{h; d}; 17{p; x;}; p' | tr -d " \t\r"  > ${foldername}/bvals_b10k
#
###### extract text between two patterns with bash awk - patterns = "##$PVM_DwEffBval=( 32 )" and "##$PVM_DwGradVec=( 32, 3 )"
#
cat ${foldername}/bvals_b2.5k > ${foldername}/bvals2
cat ${foldername}/bvals_b10k >> ${foldername}/bvals2
cat ${foldername}/bvals2 | tr "\n" " " > ${foldername}/bvals_method
xargs -a ${foldername}/bvals_method -n1 printf "%1.f " > ${foldername}/bvals


sed -n '/##$PVM_DwDir=(/,/##$PVM_DwDgSwitch/{ /PVM_DwDir/d; /##$PVM_DwDgSwitch/d; p }' ${foldername}/method_shell1 | tr " " "\n" | sed '/^[[:space:]]*$/d' | tr -d " \t\r" | tr -d " \t\r" | tr "\n" " " | sed -e "s/\([^\ ]*\ [^\ ]*\ [^\ ]*\)\ /\1\\`echo -e '\n\r'`/g" | tr "\r" "\n" | sed '/^[[:space:]]*$/d' > ${foldername}/bvecs2.5k
sed  -i '1 i\0 0 0' ${foldername}/bvecs2.5k
sed  -i '16 a\0 0 0' ${foldername}/bvecs2.5k

sed -n '/##$PVM_DwDir=(/,/##$PVM_DwDgSwitch/{ /PVM_DwDir/d; /##$PVM_DwDgSwitch/d; p }' ${foldername}/method_shell2 | tr " " "\n" | sed '/^[[:space:]]*$/d' | tr -d " \t\r" | tr -d " \t\r"| tr "\n" " " | sed -e "s/\([^\ ]*\ [^\ ]*\ [^\ ]*\)\ /\1\\`echo -e '\n\r'`/g" | tr "\r" "\n" | sed '/^[[:space:]]*$/d' > ${foldername}/bvecs10k
sed  -i '1 i\0 0 0' ${foldername}/bvecs10k
sed  -i '16 a\0 0 0' ${foldername}/bvecs10k

cat ${foldername}/bvecs2.5k > ${foldername}/bvecs_temp
cat ${foldername}/bvecs10k >> ${foldername}/bvecs_temp

/vols/Data/km/cetisca/projects/diffpostproc-exvivo-mouse-bruker7t/bin/transpose_bvecs.sh ${foldername}/bvecs_temp >  ${foldername}/bvecs

rm ${foldername}/bvals_b2.5k ${foldername}/bvals_b10k ${foldername}/bvals2 ${foldername}/bvecs_temp ${foldername}/bvecs2.5k ${foldername}/bvecs10k ${foldername}/bvals_method
