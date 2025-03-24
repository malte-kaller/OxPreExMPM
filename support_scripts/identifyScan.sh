#!/usr/bin/env bash

subj=$1
projectDIR=$2
projectname=$3


rm -f ${projectDIR}/${projectname}_rawbrukers/acquisition_order_"$subj".txt

  echo "identifying scans for $subj"

  for a in {1..90}; do
  # Define the path to the file
  filePath=${projectDIR}/${projectname}_rawbrukers/"$subj"/"$a"/acqp

  # Check if the file exists before attempting to read from it
  if [ -f "$filePath" ]; then
    # The file exists, read the line
    name=$(sed -n '13p' "$filePath" 2>/dev/null)
    echo "$a $name" >> $projectDIR/${projectname}_rawbrukers/acquisition_order_"$subj".txt
  else
    # Optional: handle the case where the file does not exist, if needed
    # For example, echo a message to a log file or just silently ignore it
    :
  fi

  done


