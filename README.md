# Pipeline details for assembling complete genomes for cucurbit yellow vine disease-causing strains of *Serratia ureilytica* of the *S. marcescens* complex

**Pipeline and Code Author:** Breah LaSarre

**Manuscript Authors:** Kephas Mphande, Breah LaSarre, Ashley A. Paulsen, Renee Hartung, Sharon Badilla-Arias, Mark L. Gleason, and Gwyn A. Beattie  

**Manuscript status:** Submitted

**Manuscript details:** Mphande K, LaSarre B, Paulsen AA, Hartung R, Badilla-Arias S, Gleason ML, and Beattie, GA. Bacteria that cause cucurbit yellow vine disease fall within the *Serratia ureilytica* species of the *S. marcescens* complex and can be vectored by cucumber beetles.

**Contact:** gbeattie@iastate.edu

## Content
 The files in this repository detail the pipeline for using Nanopore (ONT) long read sequencing to assemble complete, closed genomes for *Serratia ureilytica* strains of the *S. marcescens* complex that cause cucurbit yellow vine disease (CYVD).
</br>


## Read filtering and QC
[ONT_OneStep_filt_QC](01_ONT_OneStep_filter_QC.sh) - Bash script for one-step ONT read filtering and QC (used for for strains C01-A, CBD1, and S07)

[ONT_TwoStep_filt_QC](01_ONT_TwoStep_filt_QC.sh) - Bash script for two-step ONT read filtering and QC (used for strains CBA1 and Z07)

</br>


## Assembly

[ONT_sub_assemb_nucmer.sh](02_ONT_sub_assemb_nucmer.sh) - Bash script for subsetting and *de novo* assembly of filtered ONT reads using five different assemblers (Flye, Raven, NextDenovo, miniasm/minipolish, and Unicycler) followed by contig self-alignment to evaluate over-circularization  

*Note: This script preceeds selection of the assembies used for Trycycler consensus generation (below), so all read subsets are assembled with all 5 assemblers despite that some assemblies will be discarded.*  
</br>

## Consensus assembly generation and polishing

[Remove_terminal_redundancy](03_Remove_terminal_redundancy.md) - Text file describing the steps and commands for manually trimming overcircularized contigs to eliminate terminal redundancy

[Consensus_polishing](04_Trycycler_Medaka.md) - Text file describing the steps for creating a consensus genome assembly using Trycyler (must be done manually for each genome because there is an occasional need for manual intervention) followed by polishing with ONT reads using Medaka  
</br>

