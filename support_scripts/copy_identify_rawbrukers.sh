#!/bin/bash

# Source the project settings
source "project_settings.sh"

subj=$1

#------------------------------------------------------
#===Copy all subject data in raw Brukers format into the folder & Identify the scan

#copy the data into the "rawsbrukers" folder:
#NOTE: If concerned about space, you can just move the relevant folders. Just be aware that this is the main location for storage.
 echo "copying data for $subj"

#Copy subject folder into created folder structure (COULD BE MODFIED TO MOVE TO AVOID DOUBLE SAVE)
    #If you want to submit this command to the cluster, use this:
    ##cp1=`fsl_sub -q short -l $scriptDIR/logs/move_identify cp -r $dataDIR/$subj $projectDIR/${projectname}_rawbrukers/$subj`
    #If submitted via main script wrapper
    cp -r $dataDIR/$subj $projectDIR/${projectname}_rawbrukers/$subj

#Identify the Scans in the folder and create a .txt file containing the relecant information for this scan
    #If you want to submit this command to the cluster, use this:
    ##fsl_sub -q short -l $scriptDIR/logs/move_identify -j ${cp1}  $sup_scriptDIR/identifyScan.sh $subj $projectDIR $projectname
    $sup_scriptDIR/identifyScan.sh $subj $projectDIR $projectname
    
echo "done for $subj"

echo "Script Complete"
