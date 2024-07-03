# Transposon insertions detection with SPLITREADER and TEPID in B.napus

* TEPID_git - modified TEPID pipeline and its results on B.napus samples and A.thaliana validation
* SPLITREADER_git - modified SPLITREADER pipeline and its results on B.napus samples and A.thaliana validation
* map_to_reference.sh - map fastq files to the reference fasta
* benchmark_ins_pos - SPLITREADER, TEPID and TIF comparison on A.thaliana samples
* TE_correspond - match names from new and old annotation of Bnapus

# How to run the SPLITREADER and TEPID pipelines from scratch
## 0. Get the data and create the workspace
1) make $workspace_dir (e.g. ~/workspace_thaliana,  ~/workspace_napus)
2) make $samples_dir subdir for samples in the $workspace_dir (e.g. ~/workspace_napus/samples)
3) make $ref_dir subdir for reference files in the $workspace_dir (e.g. ~/workspace_napus/Reference)
4) make $TE_sequence_dir subdir for TE files in the $workspace_dir (e.g. ~/workspace_napus/TE_sequence)
5) get splitreader scripts to $splitreader_scripts_dir (e.g. ~/splitreader_scripts)
6) make a copy of Submit_thaliana_SPLITREADER,sh (e.g. Submit_napus_SPLITREADER,sh) which will be adjusted for your species 
7) get all required tools for SPLITREADER (bamreadcount, etc.)

### The SPLITREADER pipeline requires the following files:
* The samples of interest (paired reads: sample1_1.fastq, sample1_2.fastq, ...) in the $samples_dir
* The reference genome ($genome.fasta), which will be normalized and indexed with bowtie2 (and yaha for TEPID), in the $ref_dir
* An annotation of TE sequences in the reference genome ($TE_annotation.gff) in the $TE_sequence_dir.
* A tab-delimited file with the list of TE superfamilies in the first column and the lengths of the target-site duplications (TSDs) they generate upon insertion in the second column (superfamily_TSD.txt) in the $TE_sequence_dir. !!Ensure it has the header line as in the example. The 1 line is not processed, so without the header the first family will be skipped)!!
* A list of the names of the TE families annotated in the reference genome (TE-list.txt) in the $TE_sequence_dir.
* A fasta file ($TE_library.fa or .fasta) with the sequences of all full-length annotated reference TEs (like >ARNOLD1@Chr2:566757-567057) as well as the consensus sequences for each TE family (like >ARNOLD1@ARNOLD1) in case of degeneracy of the TE sequences present within the reference genome in the $TE_sequence_dir.
* A tab-delimited file with the name of each TE family in the first column and the name of the respective superfamily in the second column (TEfamily-superfamily.txt) in the $TE_sequence_dir.
### The TEPID pipeline requires the following files:
* The samples of interest (paired reads: sample1_1.fastq, sample1_2.fastq, ...) in the $samples_dir
* The reference genome ($genome.fasta), which will be normalized and indexed with bowtie2 (and yaha for TEPID), in the $ref_dir
* An annotation of TE sequences in the reference genome ($TE_annotation.bed) in the $TE_sequence_dir. !! The file must have tab-separated columns in the format:

`chromosome start stop strand TE_name TE_family TE_superfamily`
## 1. Map to the reference genome
1. Execute the script map_to_reference.sh (e.g. in ~ dir), where the arguments are:
    1) path to reference (the last path component is basename)
    2) path to samples (fastq files)
    3) path to output bam files
    4) reference basename

Examples:

`
bash map_to_reference.sh workspace_thaliana/Reference/TAIR10 workspace_thaliana/hcLine workspace_thaliana/BAMs TAIR10
`

or 

`bash map_to_reference.sh workspace_napus/Reference/Darmor workspace_napus/samples workspace_napus/BAMs Darmor`
## 2. Adjust the main SPLITREADER script
The copy of original main script (e.g. Submit_napus_SPLITREADER.sh) should be edited accordingly:
1) Check the variable names in the "# # # List of variable names" section
2) Check the beginning of "# # # List of samples" section (cohortname (independent samples need to be processed in the independent cohorts), bamext, etc.)
3) Check read length, library size, etc. in SPLITREADER-beta2.5_part2.sh and SPLITREADER-beta2.5_part1.sh
## 3. Run the main SPLITREADER script
Uncomment needed lines (run part) in your main script (e.g. Submit_napus_SPLITREADER.sh) and enjoy. Subsequent uncommenting and running is needed after finishing parts. You need to just run again the script with the same lines uncommented and only then change it (except for rerun: comment rerun part and then run)
## 4. Run the main TEPID script
## 5. Tips
1) Ignore `***** ERROR: Requested column 4, but database file stdin only has fields 1 - 0.`
2) It is possible to run different SPLITREADER cohorts at the same time by duplicating and renaming the main script
3) It is possible to run SPLITREADER and TEPID at the same time
4) Use tmux 
5) Before use submit_to_tepid run bash to update variables (yaha, etc.)
6) See TEPID [https://github.com/ListerLab/TEPID/tree/0.10] and SPLITREADER [https://github.com/baduelp/public/tree/master/SPLITREADER/SPLITREADER_v1.0] for details
