# OldfieldPipelines
Bioinformatic analyses snakemake pipelines developed for A Oldfield's team

# Oldfield team ChIP-seq data analysis pipeline

This is a quick start guide for this Snakemake pipeline, intended to align and analyse ChIP-seq data from an Illumina sequencer. If you need more information or have specific questions, contact Cal. If you don't know who Cal is, I'm sorry for your loss. Also, how did you get this?

If you have never used Snakemake before at all, you might want to go over the basic principles on their website:
>    https://snakemake.readthedocs.io/en/stable/

This pipeline expects a certain folder architecture, which should have been created when you unzipped the tarball that contained this README.

If you also obtained the test data provided, move it to the DATA/ folder and unzip it there.

If you want to align this data to HG38, you can download the necessary genome files here: https://genome-idx.s3.amazonaws.com/bt/GRCh38_noalt_as.zip (or perhaps browse other versions and mirror URLs here: https://bowtie-bio.sourceforge.net/bowtie2/manual.shtml).

To do so, download that file, move it to DATA/GENOMES/ and unzip it. It should be ready to use after that.

## General features

This pipeline contains a certain number of "autodetect" rules. They are designed to locate files in your DATA/ folder and run the individual rules on those files. 
They do however require the files to be named and sorted in a certain manner to detect them. They should be organised and named as so:
`DATA/{data_type}/{experiment_name}/{chipped_protein|Input}_{experimental_conditions}_{replicate_number}{paired_end_tag}{information_in_file}.{file_extension}`

For example:

DATA/BED/CTCF_H3K9ac/CTCF_T1_pos_2_filterdup_filterchr.bed

 - data_type: Browser Extensible Data (UCSC standard)
 - experiment_name: CTCF_H3K9ac (the proteins studied in this assay)
 - chipped_protein: CTCF (the protein that was selected for using an antibody)
 - experimental_conditions: T1_pos (timepoint and presence/absence of a drug)
 - replicate_number: 2 (the replicate NOTE: this needs to be a whole number. It can be 1;2;3;75000; whatever, but it needs to just be a whole number)
 - paired_end_tag: nothing (If you have paired-end, it will be tagged with _pe to indicate this)
 - information_in_file: filterdup_filterchr (the data in the file is filtered for duplicates and filtered for non-canonical chromosomes)
 - file_extension: bed (the file extension is bed)


Input files bear no replicate number. One input will be used for all the replicates of one experimental condition.
If you also obtained the test data, you should see the naming convention for the fastq files. Because there are two separate files for a paired-end experiment, the two files are tagged as "_fw" and _"rv" for forward and reverse. Once aligned, the files will bear the "_pe" tag.
You may also notice that the fastq files in the TP63 experiment already bear the "filtered" tag in their name. It is possible to use externally processed files in the pipeline, but this should be done with some care. I'd recommend looking into how Snakemake handles inputs and outputs, and then inspecting the Snakefile to look at the relevant rules you'll be bypassing.

## Local usage 

**!!MAC USERS!!** you will need to have Homebrew installed. Also, you need to comment out the lines for pysam, deeptools, macs and multiqc in burnard_smk_chipseq.yaml (add a # before the - for that line). Once you have created and activated your environment, download them using pip (something like "pip install pysam==0.22 deeptools==3.5.5 macs3==3.0.1 multiqc==1.28")

First, install micromamba:

>    https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html

Second, use micromamba to create the environment described in the config file: 

`micromamba create -f burnard_smk_chipseq.yaml`

Third, activate that environment: 

`micromamba activate smk_chipseq`

And then you should be ready to run the rules listed in Snakefile. You could for example run align_all_fastqs_autodetect using the command: 

`snakemake --cores=10 align_all_fastqs_autodetect`

or check out the DAG of jobs that will be run if you want to call peaks on all your ChIPs:

`snakemake --forceall --dag call_all_peaks_autodetect | dot -Tsvg > dag.svg`

For any rule you're curious about, you can use the "dry run" options to view which jobs and shell commands snakemake will execute when you run it for real:

`snakemake -np full_monty_autodetect`


## Cluster usage 

If you want to run this on a cluster that uses SLURM (like GenoToul), you can use the run_snakemake_slurm.sh script as a template (it is meant to be run using sbatch). If you're not using GenoToul, you'll probably need to adjust quite a few of the parametres and maybe load the tools differently (GenoToul uses modules).

Just unzip this on your server, edit run_snakemake_slurm.sh (needs at least your username), check which rule you want to run, and then you should be ready to use:

`sbatch run_snakemake_slurm`

This will run the rule specified in the script. If you want to run a different rule, you need to edit that script. You'll also see a bunch of other options appended to the command line. Feel free to edit those at your own risk.

## Parameters 

A config.yaml file should be present in the directory in which you unzipped this tarball. It already contains a few parameters required for the pipeline to run, like the path to the genome for alignment.

You can also add other parameters to it to modify their values in the rules. The naming convention for these are {rule_name}_{parameter_name}. For example, "macs3_bdgcmp_pileup_m" defines the "m" parameter (which analysis method to run) for the job "macs3_bdgcmp_pileup" (which runs the macs3 bdgcmp tool on a file obtained through macs3 pileup).

To know which parameters you can set, you'll need to look in the Snakefile. It should however be quite easy to use CTRL + F or grep to find if a parameter is editable by following this naming convention.

In the config file, simply include "macs3_bdgcmp_pileup_m: ratio" to change the operation used. You need to include this without any leading spaces or tabs, or the YAML syntax will consider it to be a dependancy of another element. 

For some of the specific rules (like "align_fastq"), the names of the files you want to process need to be given in list form under samples -> fastq. To do so, write them like this:
```
samples:
  fastq:
    - CTCF_H3K9ac/CTCF_TEST_T1_pos_1
    - CTCF_H3K9ac/CTCF_TEST_T1_pos_2
```