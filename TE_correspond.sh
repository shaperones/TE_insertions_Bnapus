#!/bin/bash

file1="$1"
file2="$2"
output_file="$3"

# Ensure the output file is empty
> "$output_file"

# Create an associative array to store the coordinates from file1
declare -A coord_dict

# Read through file1 and store the necessary columns in the associative array
while IFS=$'\t' read -r col1 col2 col3 col4 col5 col6 col7 col8 col9; do
    coord="${col1}_${col4}_${col5}"
    coord_dict["$coord"]="$col1\t$col4\t$col5\t$col9"
done < "$file1"

# Read through file2 and process rows where the coordinates match those in file1
while IFS=$'\t' read -r col1 col2 col3 col4 col5 col6 col7 col8 col9; do
    coord="${col1}_${col4}_${col5}"
    if [[ -n "${coord_dict[$coord]}" ]]; then
        id_value=$(echo "$col9" | grep -oP '(?<=;ID=)[^;]+')
        echo -e "${coord_dict[$coord]}\t$id_value" >> "$output_file"
    fi
done < "$file2"
