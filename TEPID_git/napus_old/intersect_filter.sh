#!/bin/bash

# Input and output files
file1=$1
file3=$2
file2=$3

# Create or empty the output file
> "$file2"

# Read file1 line by line and store indexes of rows with column 4 > 0
indexes=()
index=1
while IFS=$'\t' read -r col1 col2 col3 col4; do
    if (( col4 > 0 )); then
        indexes+=("$index")
    fi
    ((index++))
done < "$file1"

# Read file3 and filter rows based on the stored indexes
index=1
while IFS=$'\t' read -r col1 col2 col3 col4 col5 col6 col7 col8 col9; do
    if [[ " ${indexes[@]} " =~ " $index " ]]; then
        echo -e "$col1\t$col2\t$col3\t$col4\t$col5\t$col6\t$col7\t$col8\t$col9" >> "$file2"
    fi
    ((index++))
done < "$file3"

