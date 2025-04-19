#!/bin/bash

module add fsl
module add fsl_sub

subj=$1
source $2  # This sources the project_settings.sh file

# New input/output structure: match the new convention
input_dir="$procDIR/$subj/MPM_preprocessing"
output_dir="$input_dir"

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
    mkdir -p "$split_output_dir"
    
    # Split the 4D NIfTI file into individual 3D volumes for each echo
    fslsplit "$nifti_file" "${split_output_dir}/${base_name}_echo_" -t
    echo "Split 4D file $nifti_file into individual echoes in $split_output_dir"
    
    # Process the associated .json file if it exists
    json_file="${nifti_file%.nii}.json"
    if [[ -f "$json_file" ]]; then
        echo "Processing JSON metadata for $json_file"
        
        for ((echo=1; echo<=dim4; echo++)); do
            echo_json_file="${split_output_dir}/${base_name}_echo_$(printf "%04d" $((echo - 1))).json"
            cp -f "$json_file" "$echo_json_file"
            sed -i.bak "/\"SeriesTime\"/i \        \"EchoTime\": $echo," "$echo_json_file"
            rm -f "${echo_json_file}.bak"
            echo "Saved JSON metadata for echo $echo as $echo_json_file"
        done
    else
        echo "Warning: No JSON file found for $nifti_file"
    fi
done

echo "Processing complete. Results saved in $output_dir."