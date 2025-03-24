#!/usr/bin/env bash

#Get the
module add fsl
module add fsl_sub
source $2

#Definition of subject
subj=$1

#Define Subject directory
subDir="$procDIR"/"$subj"/MPM_preprocessing/"$subj"_NIFTI

#Defining directory to be created

  mkdir -p $subDir/DAM

  workDir=$subDir


#Checking Folder and ensureing correct DTI acquisition is name
for a in {1..90}; do
    # Define the path to the 'acqp' file
    filePath="${projectDIR}/${projectname}_rawbrukers/${subj}/${a}/acqp"

    # Check if the file exists before attempting to read from it
    if [ -f "$filePath" ]; then
        # The file exists, read the 13th line
        name=$(sed -n '13p' "$filePath" 2>/dev/null)

        # Check if 'name' contains 'DtiEpi_12_b0'
        if [[ "$name" == *"5s_FA40"* ]]; then
            Angle1=$a
        fi

        if [[ "$name" == *"5s_FA80"* ]]; then
            #echo "Folder $a contains the phrase 'DtiEpi_12_b2.5k' in its 'acqp' file."
            Angle2=$a

        fi
   #else
        #echo "File $filePath does not exist."
    fi
done

  echo $Angle1
  echo $Angle2

  # separate the two scans
  S1=$workDir/MGE2D_DAM_025iso_TR75s_FA40_"$Angle1"0001/*.nii #with flip angle alpha
  S2=$workDir/MGE2D_DAM_025iso_TR75s_FA80_"$Angle2"0001/*.nii #with flip angle 2*alpha

  echo $S1
  echo $S2
  echo "performing DAM"

  fslmaths $S1 -mul 2 $workDir/DAM/doubleS1
  fslmaths $S2 -div $workDir/DAM/doubleS1 $workDir/DAM/S2_divided_by_doubleS1
  fslmaths $workDir/DAM/S2_divided_by_doubleS1 -acos $workDir/DAM/Alpha_from_arccosine_S2_S1
  fslmaths $workDir/DAM/Alpha_from_arccosine_S2_S1 -mul 180 -div 3.141592 -div 40 -mul 100 $workDir/DAM/B1map_DAM
  cp $S1 $workDir/DAM/B1map_struct.nii
  cp $workDir/MGE2D_DAM_025iso_TR75s_FA40_"$Angle1"0001/*.json $workDir/DAM/B1map_struct.json


echo "done"
