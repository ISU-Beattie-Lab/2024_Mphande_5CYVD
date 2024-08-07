#!/bin/bash



###NOTE 1: The following script generates strain-specific script files for subsetting filtered reads, then assembling each subset using 5 different assemblers and performing self-alignment of all resulting contigs to assess over-ciruculazation
###This file automatically submits the subsetting script to the queue once it is written, and will submit the assembly script to the queue once the subsetting is complete; thus, this script both generates and executes two scripts at the appropriate time for each specified strain. To write the scripts but NOT submit to the queue, comment out the sbatch command at the end of this script.

###NOTE 2: Owing to unexpected genome complexity, we found it necessary to iteratively test different combinations of read filtering and read subsetting, which we accomplished using arrays and nested for loops. This script may still be used for simpler genomes by specifying only one term in one or more of the arrays.

###NOTE 3: This script it written with the assumption that Micromamba was installed as a static link in the user path; if this is not the case, it may be neceeary to modify the script so that Micromamba commands succeed (e.g., activate as a module)

###NOTE 4: All text that needs to be modified by the user can be found by searching for "CHANGE AS NEEDED"



##Specify the full path to working directory; CHANGE AS NEEDED
projectDir=/full/path/to/project/directory

##Set 'd' variable to the current date in YYMMDD format
d=$(date +%Y%m%d)

##specify an array ID(s) of the strain(s) being assembled; CHANGE AS NEEDED
AR1=(strain1 strain2 strain3 etc)

##specify a second array with the suffix(es) of the filtered read set(s) being used for assembly; CHANGE AS NEEDED
AR2=(filtread_1 filtread_2 etc)

##specify the approximate genome size of the strains being assembled; CHANGE AS NEEDED
g=4.9

##Specify an array for the number of subsets to generate; CHANGE AS NEEDED
AR3=(n1 n2 n3)

##The following set of nested for loops writes separate ONT read subsetting and assembly scripts for each read set/subsetting combination for the strains specified above.
for i in "${AR1[@]}"
do

	for filtReads in "${AR2[@]}"
	do

		for sb in "${AR3[@]}"
		do
	
##Define the strain-specific base directory; CHANGE AS NEEDED to match your directory structure (e.g., baseDir=$projectDir/${i}/2ndBasecall)
baseDir=$projectDir/${i}/

##Create a strain-specific scripts directory if one does not exist and move into this directory
cd $baseDir || exit
mkdir -p Scripts && cd Scripts

##Specify the full path to the filtered read directory; CHANGE AS NEEDED
readDir=$baseDir

##Set 'readSub' variable to the read subsets being generated
readSub=${filtReads}_${sb}sub

##Write the subsetting script; CHANGE AS NEEDED - specifically, the SBATCH options and Trycycler environment name
	echo "#!/bin/bash" > ${i}_${readSub}.sh
	echo "#SBATCH --time=0-23:59:00   # walltime limit (HH:MM:SS)" >> ${i}_${readSub}.sh
	echo "#SBATCH --partition=swift" >> ${i}_${readSub}.sh
	echo "#SBATCH --nodes=1   # number of nodes " >> ${i}_${readSub}.sh
	echo "#SBATCH --ntasks-per-node=16   # 16 processor core(s) per node" >> ${i}_${readSub}.sh
	echo "#SBATCH --mem=64G   # maximum memory per node" >> ${i}_${readSub}.sh
	echo "#SBATCH --job-name="${i}_${filtReads}_${sb}sub"" >> ${i}_${readSub}.sh
	echo "" >> ${i}_${readSub}.sh
	echo "##Specify the full path to base directory for this strain" >> ${i}_${readSub}.sh
	echo "baseDir=$baseDir" >> ${i}_${readSub}.sh
	echo "" >> ${i}_${readSub}.sh
	echo "##Define the variable 'i' as the strain being assembled" >> ${i}_${readSub}.sh
	echo "i=${i}" >> ${i}_${readSub}.sh
	echo "" >> ${i}_${readSub}.sh
	echo "##Define the variable 'filtReads' as the filtered ONT read set to subset" >> ${i}_${readSub}.sh
	echo "filtReads=${filtReads}" >> ${i}_${readSub}.sh
	echo "" >> ${i}_${readSub}.sh	
	echo "##Define the variable 'g' as the genome size" >> ${i}_${readSub}.sh
	echo "g=${g}" >> ${i}_${readSub}.sh
	echo "" >> ${i}_${readSub}.sh
	echo "" >> ${i}_${readSub}.sh
	echo "##Create a directory for storing read subsets (include '-p' option so that there is no error if the directory already exists)" >> ${i}_${readSub}.sh
	echo "cd $baseDir" >> ${i}_${readSub}.sh
	echo "mkdir -p ONT_subsets" >> ${i}_${readSub}.sh
	echo "" >> ${i}_${readSub}.sh
	echo 'eval "$(micromamba shell hook --shell=bash)"' >> ${i}_${readSub}.sh
	echo "micromamba activate BL_trycycler" >> ${i}_${readSub}.sh
	echo "" >> ${i}_${readSub}.sh
    echo "" >> ${i}_${readSub}.sh
	echo "##Subset each of the filtered read sets specified above" >> ${i}_${readSub}.sh
	echo "#Set 'readSub' variable to the read subsets being generated" >> ${i}_${readSub}.sh
	echo "readSub=${readSub}" >> ${i}_${readSub}.sh
	echo "" >> ${i}_${readSub}.sh
	echo "#Specify the full path to file containing filtered ONT reads" >> ${i}_${readSub}.sh
	echo "rds=$readDir/${i}_${filtReads}.fastq.gz" >> ${i}_${readSub}.sh
	echo "" >> ${i}_${readSub}.sh
	echo "cd $baseDir/ONT_subsets" >> ${i}_${readSub}.sh
	echo "trycycler subsample --reads \${rds} --genome_size ${g}m --count ${sb} --out_dir ${i}_${readSub} 2>&1 | tee ${i}_${readSub}_log.txt" >> ${i}_${readSub}.sh
	echo "" >> ${i}_${readSub}.sh
	echo "" >> ${i}_${readSub}.sh
	echo "##Now that subsetting is complete, submit assembly job to the queue" >> ${i}_${readSub}.sh
	echo "cd $baseDir/Scripts" >> ${i}_${readSub}.sh
	echo "sbatch ${i}_${readSub}_assemble.sh" >> ${i}_${readSub}.sh
	echo "" >> ${i}_${readSub}.sh
	echo "" >> ${i}_${readSub}.sh
	echo "exit" >> ${i}_${readSub}.sh


##Specify the full path to the directory containing the read subsets for assembly
subDir=$baseDir/ONT_subsets/${i}_${readSub}

##Move back to the scripts directory for writing the assembly script
cd $baseDir/Scripts

##Write the assembly script; CHANGE AS NEEDED - specifically, the SBATCH options and environment names/paths
	echo "#!/bin/bash" > ${i}_${readSub}_assemble.sh
	echo "#SBATCH --time=0-23:59:00   # walltime limit (HH:MM:SS)" >> ${i}_${readSub}_assemble.sh
	echo "#SBATCH --partition=swift" >> ${i}_${readSub}_assemble.sh
	echo "#SBATCH --nodes=1   # number of nodes " >> ${i}_${readSub}_assemble.sh
	echo "#SBATCH --ntasks-per-node=16   # 16 processor core(s) per node" >> ${i}_${readSub}_assemble.sh
	echo "#SBATCH --mem=64G   # maximum memory per node" >> ${i}_${readSub}_assemble.sh
	echo "#SBATCH --job-name="${i}_${readSub}_assembly"" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "##Specify the full path to base directory for this strain." >> ${i}_${readSub}_assemble.sh
	echo "baseDir=$baseDir" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "##Make and define a new working directory for storing the output of the assemblies for each specified read set for each strain" >> ${i}_${readSub}_assemble.sh
	echo "cd $baseDir" >> ${i}_${readSub}_assemble.sh
	echo "mkdir -p ${d}_${readSub}_all5assemble && cd ${d}_${readSub}_all5assemble" >> ${i}_${readSub}_assemble.sh
	echo "workDir=$baseDir/${d}_${readSub}_all5assemble" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "##Specify the full path to the directory containing the read subsets being assembled" >> ${i}_${readSub}_assemble.sh
	echo "readDir=$subDir" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo '##Define the variable "i" as the strain being assembled' >> ${i}_${readSub}_assemble.sh
	echo "i=${i}" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo '##Define the variable "sb" as the number of subsets being assembled' >> ${i}_${readSub}_assemble.sh
	echo "sb=${sb}" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo '##Define the variable "g" as the approximate genome size' >> ${i}_${readSub}_assemble.sh
	echo "g=${g}" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo '##Set "start" and "end" variables to two digit numbers for specifying the subset range for assemblies below' >> ${i}_${readSub}_assemble.sh
	echo '#Subsets have two-digit numbers; 'start' will always be 01, but use command to ensure that "end" is two digits regardless of the value of sb' >> ${i}_${readSub}_assemble.sh
	echo "start=01" >> ${i}_${readSub}_assemble.sh
	echo 'printf -v end "%02d" ${sb}' >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "###ASSEMBLIES###" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "##NextDenovo assembly" >> ${i}_${readSub}_assemble.sh
	echo "module load python/3.10.10-zwlkg4l" >> ${i}_${readSub}_assemble.sh
	echo "source /work/LAS/gbeattie-lab/blasarre/venv/NextDenovo/bin/activate" >> ${i}_${readSub}_assemble.sh
	echo 'export PATH="/work/LAS/gbeattie-lab/blasarre/2024_Serratia_WGS/NextDenovo:'\$PATH'"' >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "cd \$workDir" >> ${i}_${readSub}_assemble.sh
	echo 'mkdir NextDenovo && cd NextDenovo' >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo 'for s in $(eval echo "{$start..$end}"); do' >> ${i}_${readSub}_assemble.sh
	echo 'mkdir ${s} && cd ${s}' >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo '#Make input file listing the reads to use for assembly' >> ${i}_${readSub}_assemble.sh
	echo "ls \$readDir/sample_\${s}.fastq > input.fofn" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo 'echo "#Generate NextDenovo configuration file" >> ${i}_${readSub}_assemble.sh' >> ${i}_${readSub}_assemble.sh
	echo 'echo "[General]" > ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "job_type = local" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "job_prefix = ${readSub}_${s}_nextDenovo" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "task = all" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "rewrite = yes" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "deltmp = yes " >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "parallel_jobs = 20" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "input_type = raw" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "read_type = ont" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "input_fofn = input.fofn" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "workdir = $workDir/NextDenovo/${s}" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "''" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "[correct_option]" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "read_cutoff = 3k" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "genome_size = ${g}M" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "sort_options = -m 3g -t 30" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "minimap2_options_raw = -x ava-ont -t 32" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "pa_correction = 1" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "correction_options = -p 30" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "''" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "[assemble_option]" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "minimap2_options_cns = -x ava-ont -t 32 -k 21 -w 21 " >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo 'echo "nextgraph_options = -a 1" >> ND_run.cfg' >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "#Run the assembly" >> ${i}_${readSub}_assemble.sh
	echo "nextDenovo ND_run.cfg " >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "#Add strain- and read-specific prefix to output files" >> ${i}_${readSub}_assemble.sh
	echo 'cd $workDir/NextDenovo/${s}/03.ctg_graph/' >> ${i}_${readSub}_assemble.sh
	echo 'find . -maxdepth 1 -type f -name "*nd*"|while read fname; do b="$(basename "$fname")" ; mv -- "$b" "${s}_$b"; done' >> ${i}_${readSub}_assemble.sh	
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "cd \$workDir/NextDenovo" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "done" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "#Exit environment and clear modules" >> ${i}_${readSub}_assemble.sh
	echo "deactivate" >> ${i}_${readSub}_assemble.sh
	echo "module purge" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	
	echo "####The other four assemblers were all installed in conda environments, so specify micromamba language####" >> ${i}_${readSub}_assemble.sh
	echo 'eval "$(micromamba shell hook --shell=bash)"' >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	
	echo "##Flye assembly" >> ${i}_${readSub}_assemble.sh
	echo "micromamba activate BL_Flye" >> ${i}_${readSub}_assemble.sh
	echo "cd \$workDir/" >> ${i}_${readSub}_assemble.sh
	echo "mkdir Flye && cd Flye" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo 'for s in $(eval echo "{$start..$end}"); do' >> ${i}_${readSub}_assemble.sh
	echo 'mkdir ${s} && cd ${s}' >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh	
	echo "flye --nano-raw \$readDir/sample_\${s}.fastq --out-dir \$workDir/Flye/\${s} -g ${g}m" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "#Add strain- and read-specific prefix to output files" >> ${i}_${readSub}_assemble.sh 
	echo 'find . -maxdepth 1 -type f -name "*assembly*"|while read fname; do b="$(basename "$fname")" ; mv -- "$b" "${s}_flye_$b"; done' >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "cd \$workDir/Flye" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "done" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "micromamba deactivate" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	
	echo "##Raven assembly" >> ${i}_${readSub}_assemble.sh
	echo "micromamba activate BL_Raven" >> ${i}_${readSub}_assemble.sh
	echo "cd \$workDir/" >> ${i}_${readSub}_assemble.sh 
	echo "mkdir Raven && cd Raven" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo 'for s in $(eval echo "{$start..$end}"); do' >> ${i}_${readSub}_assemble.sh
	echo 'mkdir ${s} && cd ${s}' >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh	
	echo "raven \$readDir/sample_\${s}.fastq --graphical-fragment-assembly \${s}_raven.gfa" >> ${i}_${readSub}_assemble.sh
	echo 'awk "/^S/{print \">\"\$2\"\n\"\$3}" ${s}_raven.gfa > ${s}_raven.fasta' >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "cd \$workDir/Raven" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "done" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "micromamba deactivate" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	
	echo "##miniasm/minipolish assembly" >> ${i}_${readSub}_assemble.sh
	echo "micromamba activate BL_Miniasm" >> ${i}_${readSub}_assemble.sh
	echo "cd \$workDir/" >> ${i}_${readSub}_assemble.sh
	echo "mkdir miniasm && cd miniasm" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo 'for s in $(eval echo "{$start..$end}"); do' >> ${i}_${readSub}_assemble.sh
	echo 'mkdir ${s} && cd ${s}' >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh	
	echo "minimap2 -x ava-ont -t8 \$readDir/sample_\${s}.fastq \$readDir/sample_\${s}.fastq | gzip -1 > \${s}_minimap.paf.gz" >> ${i}_${readSub}_assemble.sh
	echo "miniasm -f \$readDir/sample_\${s}.fastq \${s}_minimap.paf.gz > \${s}_miniasm.gfa" >> ${i}_${readSub}_assemble.sh
	echo "minipolish \$readDir/sample_\${s}.fastq \${s}_miniasm.gfa > \${s}_miniasmpolish.gfa" >> ${i}_${readSub}_assemble.sh
	echo "awk '/^S/{print \">\"\$2\"\n\"\$3}' \${s}_miniasmpolish.gfa | fold > \${s}_miniasmpolish.fasta" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "cd \$workDir/miniasm" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "done" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "micromamba deactivate" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh

	echo "##Unicycler assembly" >> ${i}_${readSub}_assemble.sh
	echo "micromamba activate BL_unicycler" >> ${i}_${readSub}_assemble.sh
	echo "cd \$workDir/" >> ${i}_${readSub}_assemble.sh
	echo "mkdir Unicycler && cd Unicycler" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo 'for s in $(eval echo "{$start..$end}"); do' >> ${i}_${readSub}_assemble.sh
	echo "mkdir \${s} && cd \${s}" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh	
	echo "unicycler -l \$readDir/sample_\${s}.fastq -o \$workDir/Unicycler/\${s}" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh	
	echo "#Add strain- and read-specific prefix to output files" >> ${i}_${readSub}_assemble.sh
	echo 'find . -maxdepth 1 -type f -name "*assembly*"|while read fname; do b="$(basename "$fname")" ; mv -- "$b" "${s}_unicyc_$b"; done' >> ${i}_${readSub}_assemble.sh 
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "cd \$workDir/Unicycler" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "done" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "micromamba deactivate" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	
	echo "###Check contig terminal redundancy###" >> ${i}_${readSub}_assemble.sh
	echo "micromamba activate BL_mummer" >> ${i}_${readSub}_assemble.sh
	echo "cd \$workDir/" >> ${i}_${readSub}_assemble.sh
	echo "mkdir nucmer && cd nucmer" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh

##The second command for each assembler splits each assembly and creates a separate file for each contig (as new files; the original multi-contig .fasta files are left untouched) before performing contig self-alignment; the same general command is included for each assembler, just with different file paths and names depending on the output structure of each assembler.
	echo "mkdir Flye && cd Flye" >> ${i}_${readSub}_assemble.sh
    echo "for s in \$(eval echo \"{\$start..\$end}\"); do awk -v var=\"\${s}\" 'BEGIN{RS=\">\";FS=\"\n\"} NR>1{fnme=var\"_Flye_\"\$1\".fasta\"; print \">\" \$0 > fnme; close(fnme);}' \$workDir/Flye/\${s}/\${s}_flye_assembly.fasta; done" >> ${i}_${readSub}_assemble.sh
##Depending on the complexity/repetitiveness of the genome, it may be advantageous to specify a --minmatch paramter (in bp) so that the resulting dot plots and .coords files are not inundated with small repeats; however, inclusion of a --minmatch threshold can influence the detection of terminal redundancy if the redundant region is smaller than the threshold, so inclusion of this parameter should be done with caution.
	echo "for j in \$(ls *.fasta); do nucmer --maxmatch --nosimplify --prefix=\$j \$j \$j; done" >> ${i}_${readSub}_assemble.sh
	echo "for k in \$(ls *.delta); do mummerplot --prefix=\$k --png \$k; show-coords -r \$k > \$k.coords; done" >> ${i}_${readSub}_assemble.sh
	echo "cd \$workDir/nucmer/" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	
	echo "mkdir miniasm && cd miniasm" >> ${i}_${readSub}_assemble.sh
	echo "for s in \$(eval echo \"{\$start..\$end}\"); do awk -v var=\"\${s}\" 'BEGIN{RS=\">\";FS=\"\n\"} NR>1{fnme=var\"_miniasm_\"\$1\".fasta\"; print \">\" \$0 > fnme; close(fnme);}' \$workDir/miniasm/\${s}/\${s}_miniasmpolish.fasta; done" >> ${i}_${readSub}_assemble.sh
	echo "for l in \$(ls *.fasta); do nucmer --maxmatch --nosimplify --prefix=\$l \$l \$l; done" >> ${i}_${readSub}_assemble.sh
	echo "for m in \$(ls *.delta); do mummerplot --prefix=\$m --png \$m; show-coords -r \$m > \$m.coords; done" >> ${i}_${readSub}_assemble.sh
	echo "cd \$workDir/nucmer/" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	
	echo "mkdir Raven && cd Raven" >> ${i}_${readSub}_assemble.sh
	echo "for s in \$(eval echo \"{\$start..\$end}\"); do awk -v var=\"\${s}\" 'BEGIN{RS=\">\";FS=\"\n\"} NR>1{fnme=var\"_Raven_\"\$1\".fasta\"; print \">\" \$0 > fnme; close(fnme);}' \$workDir/Raven/\${s}/\${s}_raven.fasta; done" >> ${i}_${readSub}_assemble.sh
	echo "for n in \$(ls *.fasta); do nucmer --maxmatch --nosimplify --prefix=\$n \$n \$n; done" >> ${i}_${readSub}_assemble.sh
	echo "for o in \$(ls *.delta); do mummerplot --prefix=\$o --png \$o; show-coords -r \$o > \$o.coords; done" >> ${i}_${readSub}_assemble.sh
	echo "cd \$workDir/nucmer/" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh

	echo "mkdir Unicycler && cd Unicycler" >> ${i}_${readSub}_assemble.sh
	echo "for s in \$(eval echo \"{\$start..\$end}\"); do awk -v var=\"\${s}\" 'BEGIN{RS=\">\";FS=\"\n\"} NR>1{fnme=var\"_Unicyc_\"\$1\".fasta\"; print \">\" \$0 > fnme; close(fnme);}' \$workDir/Unicycler/\${s}/\${s}_unicyc_assembly.fasta; done" >> ${i}_${readSub}_assemble.sh
	echo "for p in \$(ls *.fasta); do nucmer --maxmatch --nosimplify --prefix=\$p \$p \$p; done" >> ${i}_${readSub}_assemble.sh
	echo "for q in \$(ls *.delta); do mummerplot --prefix=\$q --png \$q; show-coords -r \$q > \$q.coords; done" >> ${i}_${readSub}_assemble.sh
	echo "cd \$workDir/nucmer/" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	
	echo "mkdir NextDenovo && cd NextDenovo" >> ${i}_${readSub}_assemble.sh
	echo "for s in \$(eval echo \"{\$start..\$end}\"); do awk -v var=\"\${s}\" 'BEGIN{RS=\">\";FS=\"\n\"} NR>1{fnme=var\"_ND_\"\$1\".fasta\"; print \">\" \$0 > fnme; close(fnme);}' \$workDir/NextDenovo/\${s}/03.ctg_graph/\${s}_nd.asm.fasta; done" >> ${i}_${readSub}_assemble.sh
	echo "find . -type f -name \"* *\" -exec bash -c 'f=\"\$1\"; q=\"\${f/_ / }\"; mv -- \"\$f\" \"\${q/ *./.}\"' _ '{}' \;" >> ${i}_${readSub}_assemble.sh
	echo "for r in \$(ls *.fasta); do nucmer --maxmatch --nosimplify --prefix=\$r \$r \$r; done" >> ${i}_${readSub}_assemble.sh
	echo "for s in \$(ls *.delta); do mummerplot --prefix=\${s} --png \${s}; show-coords -r \${s} > \${s}.coords; done" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	
##The following commands create a new directory that contains the files that you will need to copy to your local machine for examining the assembly results, including assembly graphs and self-alignment coordinate and .png files.
    echo "cd \$workDir/nucmer/" >> ${i}_${readSub}_assemble.sh
	echo "mkdir ${d}_${i}_${readSub}_fortransfer && cd ${d}_${i}_${readSub}_fortransfer" >> ${i}_${readSub}_assemble.sh
	echo "AT=(Flye miniasm Raven Unicycler NextDenovo)" >> ${i}_${readSub}_assemble.sh
	echo "for y in \"\${AT[@]}\"; do mkdir -p \${y}; cp \$workDir/nucmer/\${y}/*.{png,coords} \$workDir/nucmer/${d}_${i}_${readSub}_fortransfer/\${y}; find \$workDir/\${y} -name \"[01]?_*.gfa\"|while read fname; do cp \$fname \$workDir/nucmer/${d}_${i}_${readSub}_fortransfer/\${y}; done; done" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh
	
	echo "exit" >> ${i}_${readSub}_assemble.sh
	echo "" >> ${i}_${readSub}_assemble.sh


##the chmod command alters the access permissions to the script files generated above; "u+x" specifies that the file is executable by the user that generated the file
chmod u+x ${i}_${readSub}.sh
chmod u+x ${i}_${readSub}_assemble.sh

##the next line submits the subsetting script file to the queue; if you want to write the scripts but not submit the job, tab out (add "#" at the beginning) of the next line
sbatch ${i}_${readSub}.sh
	
done

done

done

exit
