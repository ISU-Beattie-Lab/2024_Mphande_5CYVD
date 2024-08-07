# Consensus assembly generation with Trycycler and polishing with Medaka

## Requirements

Before running this step, you need to have generated multiple independent assemblies of the genome of interest. You may or may not have trimmed each of your independent assemblies to remove any terminal redundancy from over-circularized contigs, as described [here](03_Remove_terminal_redundancy.md). 

### Software needed (indicated versions are those used in the 2024 paper)
* `Trycycler` (v0.5.4) and all external tool dependencies (see https://github.com/rrwick/Trycycler/wiki/Software-requirements)
* `Medaka` (v1.11.3) 
</br>

## General notes

The reconciliation instructions here are based entirely on the Trycyler documentation available at https://github.com/rrwick/Trycycler/wiki. 

*Please read the Trycyler documentation fully before performing the steps outlined below.*  
</br>

## Procedure

### Step 1:  Copy all trimmed assemblies (.fasta format) for a given genome into a single directory ```/assemblies/``` (in accordance with Trycycler recommendations).  
</br>

### Step 2: Run the following Trycycler steps for each genome:

#### 1. Cluster
```
trycycler cluster --assemblies assemblies/*.fasta --reads reads.fastq.gz --out_dir trycycler
```
It may be necessary to discard select clusters at this stage; see Trycycler documentation for details.  
</br>

#### 2. Reconcile
*Separately reconcile each good cluster by modifying the above command to replace "XXX" with the cluster ID.*
```
trycycler reconcile --reads /FullPath/reads.fastq.gz --cluster_dir trycycler/cluster_XXX
```


It may be necessary to trim or discard individual contigs at this stage; see Trycycler documentation for details. Trimming instructions can be found [here](03_Remove_terminal_redundancy.md).  
</br>

#### 3. MSA
*Separately perform MSA on each reconciled cluster by modifying the command to replace "XXX" with the cluster ID.*  
```
trycycler msa --cluster_dir trycycler/cluster_XXX
```

</br>

#### 4. Partition
```
trycycler partition --reads reads.fastq.gz --cluster_dirs trycycler/cluster_*
```  
</br>

#### 5. Consensus
*Separately perform consensus on each partitioned cluster by modifying the command to replace "XXX" with the cluster ID.* 
```
trycycler consensus --cluster_dir trycycler/cluster_XXX
```
 
</br>

### Step 3: Polish each consensus contig with cluster-partitioned reads using Medaka
*Change the model paramter (-m) to match the basecalling model used for your reads.*
```
for c in trycycler/cluster_*; do medaka_consensus -i ${c}/4_reads.fastq -d ${c}/7_final_consensus.fasta -o ${c}/medaka -m r1041_e82_400bps_sup_v4.2.0 -t 12; mv ${c}/medaka/consensus.fasta ${c}/8_medaka.fasta; rm -r ${c}/medaka ${c}/*.fai "$c"/*.mmi; done 
```


### Step 4: Concatenate the polished consensus sequence from each cluster into a single file

```
cat trycycler/cluster_*/8_medaka.fasta > trycycler/consensus_polished.fasta 
```