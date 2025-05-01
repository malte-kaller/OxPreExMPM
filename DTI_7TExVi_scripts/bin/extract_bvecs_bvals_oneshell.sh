#### bvals
foldername=$1

#grep -A8 PVM_DwEffBval= ${foldername}/method_shell1 | tail -n+2 | tr " " "\n" | sed '/^[[:space:]]*$/d' | sed -n '2{h; d}; 17{p; x;}; p' | tr -d " \t\r" > ${foldername}/bvals_shell1 
sed -n '/PVM_DwEffBval/,/PVM_DwGradVec/{ /PVM_DwEffBval/d; /PVM_DwGradVec/d; p }' ${foldername}/method_shell1 | tr " " "\n" | sed '/^[[:space:]]*$/d' | sed -n '2{h; d}; 17{p; x;}; p' | tr -d " \t\r"  > ${foldername}/bvals_shell1


#
###### extract text between two patterns with bash awk - patterns = "##$PVM_DwEffBval=( 32 )" and "##$PVM_DwGradVec=( 32, 3 )"
#
cat ${foldername}/bvals_shell1 > ${foldername}/bvals2
cat ${foldername}/bvals2 | tr "\n" " " > ${foldername}/bvals_method
xargs -a ${foldername}/bvals_method -n1 printf "%1.f " > ${foldername}/bvals


sed -n '/##$PVM_DwDir=(/,/##$PVM_DwDgSwitch/{ /PVM_DwDir/d; /##$PVM_DwDgSwitch/d; p }' ${foldername}/method_shell1 | tr " " "\n" | sed '/^[[:space:]]*$/d' | tr -d " \t\r" | tr -d " \t\r" | tr "\n" " " | sed -e "s/\([^\ ]*\ [^\ ]*\ [^\ ]*\)\ /\1\\`echo -e '\n\r'`/g" | tr "\r" "\n" | sed '/^[[:space:]]*$/d' > ${foldername}/bvecs_shell1
#Old hardcode from Cristiana 
##sed  -i '1 i\0 0 0' ${foldername}/bvecs_shell1
##sed  -i '16 a\0 0 0' ${foldername}/bvecs_shell1

#Harcode my MSK to fit the new line - adjusted:
sed -i '1 i\0 0 0' ${foldername}/bvecs_shell1   # Insert 1st b=0
sed -i '13 a\0 0 0' ${foldername}/bvecs_shell1   # Insert 2nd b=0
sed -i '23 a\0 0 0' ${foldername}/bvecs_shell1  # Insert 3rd b=0 (after 16 DWI)

cat ${foldername}/bvecs_shell1 > ${foldername}/bvecs_temp

/vols/Data/km/cetisca/projects/diffpostproc-exvivo-mouse-bruker7t/bin/transpose_bvecs.sh ${foldername}/bvecs_temp >  ${foldername}/bvecs

#rm ${foldername}/bvals_shell1  ${foldername}/bvals2 ${foldername}/bvecs_temp ${foldername}/bvecs_shell1 ${foldername}/bvals_method
