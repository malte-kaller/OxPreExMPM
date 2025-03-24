#!/bin/bash

module add fsl
module add fsl_sub

# Define input and output directories
input_dir="/path/to/input_directory"   # Directory containing the 4D NIfTI and .json files in subfolders
output_dir="/path/to/output_directory" # Directory to save the split NIfTI and .json files

subj=$1
source $2

# Define input and output directories
#input_dir="/vols/Data/preclinical/Myelin_HJB/Projects/Pipeline_Test/RT_MYRD/RT_MYRD_preprocessing/${subj}/MPM_preprocessing/${subj}_NIFTI"   # Directory containing the 4D NIfTI and .json files in subfolders
#output_dir="/vols/Data/preclinical/Myelin_HJB/Projects/Pipeline_Test/RT_MYRD/RT_MYRD_preprocessing/20241111_185543_MYRD5_1e_ReachingTask_T2w_DTI_MPM_1_2/MPM_preprocessing/20241111_185543_MYRD5_1e_ReachingTask_T2w_DTI_MPM_1_2_NIFTI" # Directory to save the split NIfTI and .json files

input_dir="$procDIR"/"$subj"/MPM_preprocessing/"$subj"_NIFTI
output_dir=$input_dir

# Loop through each NIfTI file in subdirectories of the input directory
find "$input_dir" -type f -name "*.nii" | while read -r nifti_file; do
    # Check if the file is 4D
    dim4=$(fslval "$nifti_file" dim4)
    if [[ "$dim4" -le 1 ]]; then
        echo "Skipping $nifti_file: Not a 4D file (dim4=$dim4)"
        continue
    fi
    
    # Extract relative path and base name
    subfolder=$(dirname "$nifti_file" | sed "s|$input_dir||")
    base_name=$(basename "$nifti_file" .nii)
    
    # Create corresponding output directory
    split_output_dir="${output_dir}${subfolder}"
    mkdir -p -f "$split_output_dir"
    
    # Split the 4D NIfTI file into individual 3D volumes for each echo
    fslsplit "$nifti_file" "${split_output_dir}/${base_name}_echo_" -t
    echo "Split 4D file $nifti_file into individual echoes in $split_output_dir"
    
    # Process the associated .json file if it exists
    json_file="${nifti_file%.nii}.json"
    if [[ -f "$json_file" ]]; then
        echo "Processing JSON metadata for $json_file"
        
        # Loop through each echo to create a JSON file for each split NIfTI file
        for ((echo=1; echo<=dim4; echo++)); do
            # Define the output JSON filename
            echo_json_file="${split_output_dir}/${base_name}_echo_$(printf "%04d" $((echo - 1))).json"
            
            # Copy the original JSON file to the echo-specific JSON file
            cp -f "$json_file" "$echo_json_file"
            
            # Insert the EchoTime field before "SeriesTime" in the JSON file using sed
            sed -i.bak "/\"SeriesTime\"/i \        \"EchoTime\": $echo," "$echo_json_file"
            rm -f "${echo_json_file}.bak"  # Remove backup created by sed

            echo "Saved JSON metadata for echo $echo as $echo_json_file"
        done
    else
        echo "Warning: No JSON file found for $nifti_file"
    fi
done

echo "Processing complete. Results saved in $output_dir."
