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

#Set of Animals 1
:'
subjlist="20250219_185248_MYRD5_1a_MyReach_T2w_DTI_MPM_2_1_3
20250224_084029_MYRD5_1b_MyReach_T2w_DTI_MPM_1_1
20250224_204529_MYRD5_1e_MyReach_T2w_DTI_MPM_2_1_5
20250225_200659_MYRD5_1g_MyReach_T2w_DTI_MPM_1_1
20250226_081900_MYRD6_1f_MyReach_T2w_DTI_MPM_1_1
20250226_201908_MYRD6_1e_MyReach_T2w_DTI_MPM_1_1
20250306_185830_MYRD5_1d_MyReach_T2w_DTI_MPM_1_3
20250310_204632_MYRD6_1c_MyReach_T2w_DTI_MPM_1_1
20250311_202944_MYRF30_1g_MyReach_T2w_DTI_MPM_1_1
20250312_213047_MYRF31_1f_MyReach_T2w_DTI_MPM_1_1
20250313_202917_MYRF28_1c_MyReach_T2w_DTI_MPM_1_1
20250314_212530_MYRF30_1b_MyReach_T2w_DTI_MPM_1_1
20250315_093441_MYRF31_1b_MyReach_T2w_DTI_MPM_1_1
20250315_211100_MYRF28_1f_MyReach_T2w_DTI_MPM_1_1
20250316_091337_MYRF30_1f_MyReach_T2w_DTI_MPM_1_1
20250316_213307_MYRF29_1d_MyReach_T2w_DTI_MPM_1_1
20250317_213241_MYRF28_1b_MyReach_T2w_DTI_MPM_1_1
20250318_213305_MYRF31_1a_MyReach_T2w_DTI_MPM_1_1
20250319_213738_MYRF28_1a_MyReach_T2w_DTI_MPM_1_1
20250320_214203_MYRF29_1b_MyReach_T2w_DTI_MPM_1_1
20250321_212953_MYRF31_1c_MyReach_T2w_DTI_MPM_1_1
20250322_095004_MYRF30_1a_MyReach_T2w_DTI_MPM_1_1
20250322_212900_MYRF30_1d_MyReach_T2w_DTI_MPM_1_1
20250323_100949_MYRF28_1e_MyReach_T2w_DTI_MPM_1_1
20250323_221240_MYRF29_1a_MyReach_T2w_DTI_MPM_1_1
20250324_203036_MYRF30_1e_MyReach_T2w_DTI_MPM_1_1
20250325_211718_MYRF30_1c_MyReach_T2w_DTI_MPM_1_1
20250326_203933_MYRF31_1d_MyReach_T2w_DTI_MPM_1_1
20250327_192739_MYRF29_1f_MyReach_T2w_DTI_MPM_1_1
20250331_205505_MYRF30_1h_MyReach_T2w_DTI_MPM_1_1
20250401_204933_MYRF31_1g_MyReach_T2w_DTI_MPM_1_1
20250404_210449_MYRF30_1i_MyReach_T2w_DTI_MPM_1_1
20250405_092017_MYRF31_1e_MyReach_T2w_DTI_MPM_1_1
20250405_212517_MYRF28_1g_MyReach_T2w_DTI_MPM_1_1
20250406_092545_MYRF29_1e_MyReach_T2w_DTI_MPM_1_1
20250406_210803_MYRF19_2g_MyReach_T2w_DTI_MPM_1_1
20250407_212135_MYRF18_2d_MyReach_T2w_DTI_MPM_1_1
20250408_205837_MYRF18_2c_MyReach_T2w_DTI_MPM_1_1
20250414_213035_MYRF18_2a_MyReach_T2w_DTI_MPM_1_2"
'

#Set of Animals 2
subjlist="20250611_194551_MYRD8_2a_MyReach_T2w_DTI_MPM_1_1
20250612_192313_MYRD8_2b_MyReach_T2w_DTI_MPM_1_1
20250614_202055_MYRD8_2e_MyReach_T2w_DTI_MPM_1_1
20250615_105715_MYRD8_2f_MyReach_T2w_DTI_MPM_1_1
20250623_192916_MYRD13_1a_MyReach_T2w_DTI_MPM_1_1
20250624_200543_MYRD13_1b_MyReach_T2w_DTI_MPM_1_1
20250625_194802_MYRD13_1d_MyReach_T2w_DTI_MPM_1_1
20250626_194932_MYRD13_1f_MyReach_T2w_DTI_MPM_1_1
20250627_081621_MYRD13_1g_MyReach_T2w_DTI_MPM_1_1
20250627_195007_MYRD13_1c_MyReach_T2w_DTI_MPM_1_1
20250628_081404_MYRD8_2d_MyReach_T2w_DTI_MPM_1_2
20250628_194600_MYRF30_1h_MyReach_T2w_DTI_MPM_2_1_2
20250629_080433_MYRF29_1f_MyReach_T2w_DTI_MPM_2_1_2
20250629_193904_MYRF31_1g_MyReach_T2w_DTI_MPM_2_1_2"

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
