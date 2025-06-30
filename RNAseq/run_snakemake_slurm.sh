#!/bin/bash
#SBATCH --cpus-per-task=4       # run on one node with 4 cpus
#SBATCH -n 1                    # Number of cores. For now 56 is the number max of core available on Genotoul
#SBATCH --mem=100M		# total memory allocation (specify unit eg K,M,G,T,...) (Snakemake won't need a lot, it's just to run the "supervisor" job that will submit each individual job to the queue)
#SBATCH -t 3-23:59              # Runtime in D-HH:MM
#SBATCH -o log_%u_%j.out      # File to which STDOUT will be written
#SBATCH -e log_%u_%j.err      # File to which STDERR will be written
#SBATCH --partition=workq

## run the application below. Example:
source /home/aoldfield/save/modules/smk/bin/activate ## python virtual environment containing snakemake, MACS3, deeptools
export LD_LIBRARY_PATH=/tools/devel/python/Python-3.11.1/lib/:$LD_LIBRARY_PATH
module load bioinfo/fastq_illumina_filter/0.1
module load bioinfo/FastQC/0.12.1 
module load bioinfo/bowtie/2.5.1 
module load bioinfo/samtools/1.20 
module load statistics/R/4.4.0 ## need to check this is correct ver


# snakemake -np call_all_peaks_autodetect ## run no jobs, print list of jobs and their params that would be run for job call_all_peaks_autodetect
# snakemake -p --forceall --dag call_all_peaks_autodetect  | dot -Tsvg >dag_$SLURM_JOB_ID.svg ## run no jobs, create plot of the DAG of jobs to run for rule call_all_peaks_autodetect (unsure if this works on Genotoul tbh, dot requires graphviz)
snakemake --slurm --rerun-incomplete --keep-going --jobs 5 andold_autodetect  --default-resources slurm_account=YOUR_ACCOUNT_NAME slurm_partition=workq ## run up to 5 jobs in parallel for rule andold_autodetect

## if you need to set specific resource requirements for jobs, do so like this : --set-resources bowtie2_map_se:mem_mb=64000 bowtie2_map_pe:mem_mb=96000
