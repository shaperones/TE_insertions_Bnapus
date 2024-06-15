#!/bin/bash

# Paired reads directory end-to-end mapping to the reference

Ref=$1 # path/to/ref_base (example: TAIR10.1.bt -> ref_base=TAIR10)
SampleDir=$2 # path/to/samples
OutputDir=$3 # path/to/output/dir
ref_base=$4 # ref_base and extension for output (e.g. sample_ext_dupl_fixed_paired.bam)
MP=13
RFG=8,5
RDG=8,5
THREADS=32
java=~/jdk-21.0.1/bin/java # java executable
picard=~/picard.jar # picard executable

# Shortkeys
RN=1 # normalize the reference genome and build with bowtie2 and yaha
RB=1 # run bowtie2 to map
RS=1 # run samtools to sort
RP=1 # run picard to remove duplicates
RG=1 # gzip samples and move to 'done' dir
RU=1 # extract unmapped reads from bams
RD=1 # delete fastq
RJ=1 # add to ~/jbrowse2

RN=0
# RB=0
# RS=0
# RP=0
RG=0
RU=0

# Ensure output directory exists
mkdir -p "$OutputDir"

if [ $RN -gt 0 ]; then
	$java -jar $picard NormalizeFasta -I ${Ref}.fasta -O ${Ref}.norm.fasta
	cp ${Ref}.norm.fasta ${Ref}.fasta
	RefDir="${Ref%/*}"
	cd $RefDir
	bowtie2-build --threads $THREADS ${Ref}.fasta $ref_base 
	cd ~
	yaha -g ${Ref}.fasta -H 2000 -L 11
fi	


for file1 in "$SampleDir"/*_1.fastq; do

    # Ensure matching file2 exists for each file1
    file2="${file1/_1.fastq/_2.fastq}"
    
    if [ ! -f "$file2" ]; then
        echo "Error: Corresponding file not found for $file1"
        exit 1
    fi

    # Extract sample base name
    # file1="${file1%.*}"
    # file2="${file2%.*}"
    SampleBase="$(basename $file1 _1.fastq)"

    #Unzip
    # echo "Unzipping $file1"
    # gzip -d "${file1}.gz"
    # echo "Unzipping $file2"
    # gzip -d "${file2}.gz"

    # Run bowtie2
    if [ $RB -gt 0 ]; then
	echo "Running bowtie2 mapping for $file1 and $file2"
    	bowtie2 -x "$Ref" -1 "$file1" -2 "$file2" -S "${OutputDir}/${SampleBase}_${ref_base}.sam" --very-sensitive --mp "$MP" --rdg "$RDG" --rfg "$RFG" --time --threads "$THREADS"
    fi

    # Run samtools to sort
    if [ $RS -gt 0 ]; then
	    echo "Running samtools sorting for $file1 and $file2"
	    samtools view -bS "${OutputDir}/${SampleBase}_${ref_base}.sam" > "${OutputDir}/${SampleBase}_${ref_base}.bam"
	    rm "${OutputDir}/${SampleBase}_${ref_base}.sam"
	    samtools sort "${OutputDir}/${SampleBase}_${ref_base}.bam" -o "${OutputDir}/${SampleBase}_${ref_base}_sorted.bam"
	    rm "${OutputDir}/${SampleBase}_${ref_base}.bam"
    fi

    # Run picard to remove PCR and sequencing duplicates
    if [ $RP -gt 0 ]; then
	    echo "Marking duplicates for $file1 and $file2"
	    $java -jar $picard MarkDuplicates -I "${OutputDir}/${SampleBase}_${ref_base}_sorted.bam" -M "${OutputDir}/${SampleBase}_${ref_base}_metrics.txt" -O "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired.bam" --REMOVE_DUPLICATES
	    rm "${OutputDir}/${SampleBase}_${ref_base}_sorted.bam"
    fi

    # Gzip sample 
    if [ $RG -gt 0 ]; then
	    #mkdir -p "${SampleDir}/done"
    	    #echo "Gzipping  $file1 and $file2"
    	    gzip $file1
    	    gzip $file2
    	    #$mv "${file1}.gz" "${SampleDir}/done"
    	    #$mv "${file2}.gz" "${SampleDir}/done"
	    
    fi

    # Extract unmapped reads
    if [ $RU -gt 0 ]; then
	    # extract unmapped reads and their mates from BAM
	    samtools view -h -f 4 "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired.bam" > "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired_unmapped.sam"
	    samtools view -f 8 "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired.bam" >> "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired_unmapped.sam"
	    # convert to BAM
	    samtools view -Su "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired_unmapped.sam" > "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired_unmapped.bam"
	    samtools sort "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired_unmapped.bam" -o "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired_unmapped_sorted.bam"
	    mv "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired_unmapped_sorted.bam" "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired_unmapped.bam" 
	    rm "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired_unmapped.sam" 
	    samtools index "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired_unmapped.bam"
    fi 

    # Delete fastq
    if [ $RD -gt 0 ]; then
	    #if [ -s "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired_unmapped.bam" ] && [ -s "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired_unmapped.bam.bai" ] && [ -s "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired.bam" ]; then
	    if [ -s "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired.bam" ]; then
	    	    rm $file1
		    rm $file2
	    fi
    fi



    # Add reads to jbrowse2
    if [ $RJ -gt 0 ]; then
	    #jbrowse add-track "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired_unmapped.bam" --out ~/jbrowse2 --load symlink
	    jbrowse add-track "${OutputDir}/${SampleBase}_${ref_base}_dupl_fixed_paired.bam" --out ~/jbrowse2 --load symlink
    fi

    echo "### Finished $SampleBase ###"
	
done

