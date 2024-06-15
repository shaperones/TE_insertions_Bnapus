#!/bin/bash

# Submit several FASTQ paired reads genomes in the current directory to TEPID
# The script activates a conda environment named as the cohortname, finds paired reads, creates the list of samples, runs tepid-map and tepid-discover for each sample. The samples are then moved to the 'done' subdir (so it helps to skip done samples when restarting the script). If samples are related (from the same population), insertions and deletions can be merged and tepid-refine can then be run. 

Ref=$1 # path/to/ref_base (example: TAIR10.1.bt -> ref_base=TAIR10)
suffix=$2 # common suffix (example: genome_hcLine)
TE=$3 # /path/to/TE_annotation.bed
SampleDir=$4
ScriptsDir=$5
THREADS=32
insert_size=350
yaha_index='X11_01_02000S'
cohortname="TE_capture_accessions_3"
conda_env=$cohortname

#Shortcuts
RM=1 # run tepid-map
RD=1 # run tepid-discover
RME=1 # merge deletions and insertions
RR=1 # run tepid-refine

RM=0
RD=0
#RME=0
#RR=0


# Prepare the environment
echo "Activating conda environment"
eval "$($(which conda) 'shell.bash' 'hook')"
conda activate $conda_env

# Find paired reads file1
echo "Processing samples"
rm ${SampleDir}/${cohortname}.tepid_samples.list
#for file1 in ${SampleDir}/*_1.fastq; do
for file1 in ${SampleDir}/*.split.bam; do

	# Ensure matching file2 exists for each file1
	#file2="${file1/_1.fastq/_2.fastq}"
	
	#if [ ! -f "$file2" ]; then
	#	echo "Error: Corresponding file not found for $file1"
	#	exit 1
    	#fi

	# Extract sample base name
	#filename="$(basename $file1 _1.fastq)"
	filename="$(basename $file1 .split.bam)"
	echo $filename >> ${SampleDir}/${cohortname}.tepid_samples.list
	
	# Map
	if [ $RM -gt 0 ]; then 
		# echo "Mapping $filename"
		if [ "$filename" == "sub_Ningyou7" ]; then
			echo "i see Ningyou7"
			${ScriptsDir}/tepid-map -x $Ref -y ${Ref}.${yaha_index} -p $THREADS -s 300  -n $filename  -1 "$file1" -2 "$file2"
		else
			echo "not Ningyou7" 	
			${ScriptsDir}/tepid-map -x $Ref -y ${Ref}.${yaha_index} -p $THREADS -s $insert_size -n $filename  -1 "$file1" -2 "$file2"
		fi
	fi
	
	# Discover
	if [ $RD -gt 0 ]; then
		echo "Discovering $filename"
		${ScriptsDir}/tepid-discover -p $THREADS -s $filename.split.bam -n $filename -c $filename.bam -t $TE
	fi

	# Move sample to 'done' dir
    	# mkdir -p "${SampleDir}/done"
    	# mv "$file1" "${SampleDir}/done"
    	# mv "$file2" "${SampleDir}/done"
    	echo "### Finished $filename ###"

done

# Merge deletions and insertions
if [ $RME -gt 0 ]; then
	mkdir $suffix
	mv insertions_$suffix* $suffix
	mv deletions_$suffix* $suffix
	echo "deletions_$suffix"
	echo "insertions_$suffix"
	echo $PWD
	python ${ScriptsDir}/merge_deletions.py -f "deletions_$suffix" -d $suffix
	rm "$suffix/deletions_$suffix.bed"
	echo "print pwd: $PWD" 
	python ${ScriptsDir}/merge_insertions.py -f "insertions_$suffix" -d $suffix
	rm "$suffix/insertions_$suffix.bed"
	rm "$suffix/insertions_${suffix}_poly_te.bed"
fi

# Refine variant calls
if [ $RR -gt 0 ]; then
	for file1 in ${SampleDir}/*.split.bam; do
		filename="$(basename $file1 .split.bam)"
		${ScriptsDir}/tepid-refine -i "insertions_$suffix.bed" -d "deletions_$suffix.bed" -p $THREADS -s $filename.split.bam -n $filename -c ${filename}.bam -t $TE -a ${SampleDir}/${cohortname}.tepid_samples.list
	done
fi

conda deactivate

