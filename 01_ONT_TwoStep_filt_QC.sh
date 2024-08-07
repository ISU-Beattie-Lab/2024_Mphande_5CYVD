#!/bin/bash
 


##Set 'd' variable to the current date in YYMMDD format
d=$(date +%Y%m%d)

##Assign the names of the strains to be assembled to array "AR" 
AR=(CBA-1 Z07)

##Specify the full path to folder containing the raw Nanopore reads (not yet filtered)
rawread=/full/path/to/raw/read/directory

##Specify the file suffix for the raw Nanopore reads
rawsuf=ext_raw

##Specify the naming extension to use for this read set
rs=ExtOnly

##Run the same filtering and QC analysis for each of the strains defined in the array using a for loop
for c in "${AR[@]}"; do

##Create a directory for storing the filtered reads from this read set, if one does not already exist, and set this as the working directory
cd /path/to/strain/directory/${c}
mkdir -p ${rs}
workDir=/path/to/strain/directory/${c}/${rs}

#####READ FILTERING#####
###Activate the NanoPack virtual environment
module load python/3.10.10-zwlkg4l 
source /full/environment/path/venv/nanopack/bin/activate

###Use FiltLong to first filter reads with a length cutoff of "l", then keep only the best "p"% of the remaining reads.
l=3500
p=90

/full/path/to/tool/Filtlong/bin/filtlong --min_length ${l} $rawread/${c}_${rawsuf}.fastq.gz | gzip > $workDir/${c}_${rs}_l${l}.fastq.gz

/full/path/to/tool/Filtlong/bin/filtlong --keep_percent ${p} $workDir/${c}_${rs}_l${l}.fastq.gz | gzip > $workDir/${c}_${rs}_l${l}p${p}.fastq.gz

#####READ QC#####
##Create a subdirectory within the working directory for storing the QC output, if one does not already exist
cd $workDir
mkdir -p read_QC

##QC and comparison of raw and filtered read sets using NanoComp
NanoComp --fastq $rawread/${c}_${rawsuf}.fastq.gz $workDir/${c}_${rs}_l${l}p${p}.fastq.gz -p ${c}_${rs}_ --names raw l${l}p${p} -o $workDir/read_QC/${d}_${c}_${rs}_l${l}p${p}_NanoComp

deactivate
module purge

done

exit