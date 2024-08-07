###NOTE: Strains C01-A, CBD1, and S07 were all subjected to the same one-step read filtering approach but the raw read sets were slightly different, as C01-A and S07 were sequenced once whereas CBD1 was sequenced twice and the read sets combined prior to filtering (using the command: zcat CBD1_read_set_1.fastq.gz CBD1_read_set_2.fastq.gz | gzip -c > CBD1_merged.fastq.gz ). 
###This script has file naming conventions specific to C01-A and S07; the same filtering and QC commands were used for CBD1 but using a merged-read-specific naming scheme.



#!/bin/bash



##Set 'd' variable to the current date in YYMMDD format
d=$(date +%Y%m%d)

##Assign the names of the strains to be assembled to array "AR"
AR=(C01-A S07)

##Specify the full path to folder containing raw Nanopore reads (not yet filtered)
rawread=/full/path/to/raw/read/directory

##Specify the file suffix for the raw Nanopore reads
rawsuf=Nanopore

##Specify the naming extension to use for this read set
rs=ONT

##Run the same filtering and QC analysis for each of the strains defined in the array using a for loop
for c in "${AR[@]}"; do

##Create a directory for storing the filtered reads from this read set, if one does not already exist, and set this as the working directory
cd /path/to/strain/directory/${c}/
mkdir -p 2ndBasecall
workDir=/path/to/strain/directory/${c}/2ndBasecall

#####READ FILTERING#####
###Activate the NanoPack virtual environment
module load python/3.10.10-zwlkg4l 
source /full/environment/path/venv/nanopack/bin/activate 

###Use FiltLong to keep only the best "p"% of reads and reads longer than "l" bp
l=2500
p=80

/full/path/to/tool/Filtlong/bin/filtlong --min_length ${l} --keep_percent ${p} ${rawread}/${c}_${rawsuf}.fastq | gzip > $workDir/${c}_${rs}_p${p}l${l}.fastq.gz


#####READ QC#####
##Create a subdirectory within the working directory for storing the QC output, if one does not already exist
cd $workDir
mkdir -p read_QC

##QC and comparison of raw and filtered read sets using NanoComp
NanoComp --fastq $rawread/${c}_${rawsuf}.fastq $workDir/${c}_${rs}_p${p}l${l}.fastq.gz -p ${c}_${rs} --names raw p${p}l${l} -o $workDir/read_QC/${d}_${c}_${rs}_p${p}l${l}_NanoComp

deactivate
module purge

done

exit

