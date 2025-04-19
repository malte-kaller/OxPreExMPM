#!/usr/bin/env bash

# This script is the starting point.
   #Creates the basic folder structure for the project.
   #Defines the key paths and subjectlist for the project that will be used by subsequent processing

#Add the relevant modules here. Relevant for the platform you are on
module add fsl
module add fsl_sub

#---DEFINE BASIC PARAMETERS FOR PROJECT------------------

#Define the name of the project
projectname="ReTa_Yingshi"

#Define path to folder in project should be created
workDIR="/vols/Data/preclinical/Myelin_HJB/Projects/"

#That creates the project directory:
projectDIR=$workDIR/$projectname

#Define the path to where BRUKERS raw data folders are stored.
dataDIR="/vols/Data/preclinical/Yingshi/ReachingTask_T2w_DTI_MPM"

#Define the location of the folder containing the scripts - that is where you should be right now (pwd)
scriptDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#Define a list of subjects by listing their folder names as defined in dataDIR

subjlist="20250219_185248_MYRD5_1a_MyReach_T2w_DTI_MPM_2_1_3
20250224_084029_MYRD5_1b_MyReach_T2w_DTI_MPM_1_1"

#--------------------------------------------------------

echo "subjects are $subjlist"

#===Create folders for the project

#Locations of all support scripts, contain scripts that are submitted and do the actual work
sup_scriptDIR=$scriptDIR/support_scripts


#Folder for raw Brukers data
rawBruDIR=$projectDIR/${projectname}_rawbrukers
mkdir -p $projectDIR/${projectname}_rawbrukers
#Folder for preprocessing data
procDIR=$projectDIR/${projectname}_preprocessing
mkdir -p $projectDIR/${projectname}_preprocessing
#Folder that contains all subject data in organised manner - Bids like format
bidsDIR=$projectDIR/${projectname}_databids
mkdir -p $projectDIR/${projectname}_databids

#------------------------------------------------------
# Write the variables to a text file in both the project and script DIR
# Write the variables to a shell script in both directories

rm "$projectDIR/project_settings.sh"
rm "$scriptDIR/project_settings.sh"

{
    echo "export projectname=\"$projectname\""
    echo "export workDIR=\"$workDIR\""
    echo "export dataDIR=\"$dataDIR\""
    echo "export scriptDIR=\"$scriptDIR\""
    echo "export sup_scriptDIR=\"$sup_scriptDIR\""
    echo "export subjlist=\"$subjlist\""
    echo "export projectDIR=\"$projectDIR\""
    echo "export rawBruDIR=\"$rawBruDIR\""
    echo "export procDIR=\"$procDIR\""
    echo "export bidsDIR=\"$bidsDIR\""
} > "$projectDIR/project_settings.sh"

# Copy the settings file to the script directory as well
cp "$projectDIR/project_settings.sh" "$scriptDIR/project_settings.sh"

#------------------------------------------------------
#===Copy all subject data in raw Brukers format into the folder & Identify the scan

#For loop for each subject
for subj in $subjlist; do

#copy the data into the "rawsbrukers" folder:
#NOTE: If concerned about space, you can just move the relevant folders. Just be aware that this is the main location for storage. 
##If that is desired, switch between the two options for scripts below
 
 #echo "copying and identifying data for $subj"
 fsl_sub -q short -l $scriptDIR/logs $sup_scriptDIR/copy_identify_rawbrukers.sh $subj

# echo "moving and identifying data for $subj"
# fsl_sub -q short -l $scriptDIR/logs $sup_scriptDIR/move_identify_rawbrukers.sh $subj

echo "done for $subj"

done

echo "Script Complete"
