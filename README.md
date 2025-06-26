# OldfieldPipelines - Oldfield team NGS data analysis pipeline

Bioinformatic analyses snakemake pipelines developed for A Oldfield's team

This is a quick start guide for this Snakemake pipeline, intended to align and analyse ChIP-seq data from an Illumina sequencer. If you need more information or have specific questions, contact Cal. If you don't know who Cal is, I'm sorry for your loss. Also, how did you get this?

If you have never used Snakemake before at all, you might want to go over the basic principles on their website:
>    https://snakemake.readthedocs.io/en/stable/

This pipeline expects a certain folder architecture, which should have been created when you cloned this git repo or unzipped the tarball that contained this README.

# General features

This pipeline contains a certain number of "autodetect" rules. They are designed to locate files in your DATA/ folder and run the individual rules on those files. 
They do however require the files to be named and sorted in a certain manner to detect them. They should be organised and named as so:
`DATA/{data_type}/{experiment_name}/{chipped_protein|Input}_{experimental_conditions}_{replicate_number}{paired_end_tag}{information_in_file}.{file_extension}`

For example:

DATA/BED/CTCF_H3K9ac/CTCF_D1_2_filterdup_filterchr.bed

 - data_type: Browser Extensible Data (UCSC standard)
 - experiment_name: CTCF_H3K9ac (the proteins studied in this assay)
 - chipped_protein: CTCF (the protein that was selected for using an antibody)
 - experimental_conditions: D1 (timepoint and other info, can contain underscores)
 - replicate_number: 2 (the replicate NOTE: this needs to be a whole number. It can be 1;2;3;75000; whatever, but it needs to just be a whole number)
 - paired_end_tag: nothing (If you have paired-end data, it will be tagged with _pe to indicate this)
 - information_in_file: filterdup_filterchr (the data in the file is filtered for duplicates and filtered for non-canonical chromosomes)
 - file_extension: bed (the file extension is bed)


Input files have no replicate number. One input will be used for all the replicates of one experimental condition.
If you also obtained the test data, you should see the naming convention for the fastq files. If there are two separate files for a paired-end experiment, the two files should be tagged as "_fw" and _"rv" for forward and reverse. Once aligned, the files will bear the "_pe" tag.
You may also add the ".filtered" tag in your fastq file names. It is possible to use externally processed files in the pipeline, but this should be done with some care. I'd recommend looking into how Snakemake handles inputs and outputs, and then inspecting the Snakefile to look at the relevant rules you'll be bypassing.

# Local usage 

To start, clone this repo or download it as a zip and unzip it. Open up a terminal, then navigate into the folder created when you unzipped it.

## Setting up the environment 

The following instructions are provided first for Linux distribution then for MacOS. If you use Windows, I would recommend installing a Linux VM on your machine, for example using WSL2. Youshould only need to run these steps once.

For everyone: 

Once the environment is set up, if you are not admin of your computer, you may have issues running some of the scripts included in this pipeline (in ChIPseq/SCRIPTS and ATACseq/SCRIPTS). If so, you can try copying those scripts from the archive server (if you're at the IGH) under commun/Callum BURNARD/ChIPseq_SCRIPTS. If you're not at the IGH, reach out to your IT department.

If you want to align this data to HG38, you can download the necessary genome files here: https://genome-idx.s3.amazonaws.com/bt/GRCh38_noalt_as.zip (or perhaps browse other versions and mirror URLs here: https://bowtie-bio.sourceforge.net/bowtie2/manual.shtml). You will need to navigate to the Genomes folder of the relevant pipeline and place it there for ChIPseq or ATACseq. For RNAseq, the genome setup is part of the pipeline.

### Linux distributions

#### Installing micromamba:

>    https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html

#### Creating the environment

The environment is described in the config file: 

`micromamba create -f smk_chipseq.yaml`

```
cd ChIPseq/DATA/GENOMES
wget https://genome-idx.s3.amazonaws.com/bt/GRCh38_noalt_as.zip
unzip GRCh38_noalt_as.zip
cd ../../..
```


### MacOS

You will most likely need to have Homebrew installed.

#### Download Miniconda

Open your browser and go to: https://www.anaconda.com/docs/getting-started/miniconda/install#mac-os and scroll down to "Quickstart install instructions"

Open Terminal (search “Terminal” in Spotlight).

Copy and paste the installation code (watch out, there should be two options: Apple Silicon or Intel, depending on the hardware of your Mac. If your Mac is M1/M2 then choose Apple Silicon, otherwise look it up.)

Be sure to run the "source" command after the main block of code in that section, it shows your computer where to find the program you just installed! Then, run this so that it will always be visible to your computer:

echo 'export PATH="$HOME/miniconda3/condabin:$PATH"' >> ~/.zshrc

Close and reopen the Terminal.

#### Create the environment

In Terminal, run the following commands:

```
conda init zsh 

conda create -n smk_chipseq python=3.10.14 -y

conda activate smk_chipseq

conda config --add channels conda-forge
conda config --add channels bioconda

conda install -y \
  pysam=0.22 \
  deeptools=3.5.5 \
  snakemake=7.32.4 \
  matplotlib=3.8.4 \
  samtools=1.20 \
  bowtie2=2.5.4 \
  fastqc=0.12.1 \
  jinja2=3.1.4 \
  pulp=2.7 \
  pygments=2.15.1 \
  bedtools=2.31.1 \
  multiqc=1.28

pip install macs3==3.0.1 graphviz


snakemake --version



```
This installs all necessary tools into a named environment called smk_chipseq.


## Activating your environment

You'll need to do this each time you open a new terminal to run the Snakemake pipeline.

### Linux distributions

To activate the environment: 

`micromamba activate smk_chipseq`

You’ll now see (smk_chipseq) at the start of your terminal prompt, which means you're using the correct tools.

And to exit the environment:

`micromamba deactivate`


### MacOS

To activate the environment: 

`conda activate smk_chipseq`

You’ll now see (smk_chipseq) at the start of your terminal prompt, which means you're using the correct tools.

And to exit the environment:

`conda deactivate`

## Running the pipeline

### Data preparation

If you're just starting out and want to run this pipeline on the test data provided, run

```
mv test_data_chr20 ChIPseq/DATA/FASTQ
cd ChIPseq
```

Or if you have your own ChIP-seq data you want to try this out on, create an experiment folder in DATA/FASTQ and put the files there:

```
cd ChIPseq
mkdir DATA/FASTQ/my_experiment
cp path/to/my/files/*.fq.gz DATA/FASTQ/my_experiment
```

And then you should be ready to run the rules listed in Snakefile. 

### Different rules

There are a few different rules available to run, in particular for the ChIPseq pipeline.

#### ChIPseq

 - andold_autodetect: runs the main steps of the ChIPseq analysis pipeline, as specified by A OLDFIELD
 - full_monty_autodetect: runs the main steps of the pipeline with a few extra normalisation options
 - histone_batch: calculates a PCA containing all histone modifications (their names start with H and then a number) in all experiments
 - tf_batch: calculates a PCA containing all transcription factors (everything that isn't a histone mod) in all experiments
 - align_all_fastqs_autodetect: stops after aligning all fastq files found in the data folder
 - call_all_peaks_autodetect: stops after calling all peaks on files found in the fastq data folder
 - compare_all_bigwigs_autodetect: stops after normalising BigWigs to input
 - PCA_all_bws_autodetect: calculates a PCA for each experiment directory

 - align_fastq: align fastq files (Requires user input. See final section of this README)
 - call_narrow_peaks: call narrow peaks (Requires user input. See final section of this README)
 - call_broad_peaks: call broad peaks (Requires user input. See final section of this README)
 - call_bdg_peaks: call peaks using bdgpeakcall (Requires user input. See final section of this README)

#### ATACseq

 - andold_autodetect: runs the main steps of the ATACseq analysis pipeline, as specified by A OLDFIELD
 - PCA_all_bws: calculates a PCA for each experiment directory

#### RNAseq

 - andold_autodetect: runs the main steps of the RNAseq analysis pipeline, as specified by A OLDFIELD

### Different commands

Start by checking out which tools will be run (and the shell commands used) using a "dry-run":

`snakemake -np andold_autodetect`

or check out the graph of jobs that will be run. This will be saved as "dag.svg"

`snakemake --forceall --dag andold_autodetect | dot -Tsvg > dag.svg`

You should now be ready to run the pipeline on your device. How many cores you dedicate to it depends on how powerful your machine is, I wouldn't recommend more than 8 unless it was designed to run this kind of software. You might not be able to use it much while all this is running, as it can get quite intensive.

`snakemake --cores=4 andold_autodetect`

If you cancel the Snakemake pipeline at some point (using Ctrl+C) or if a rule crashes, you may need to use `snakemake --unlock` to enable it to run again. You might also want to consider using `snakemake --keep-going --rerun-incomplete --cores=...` to keep the pipeline running even if one job fails, and to restart any job that failed or was cancelled in a previous run.

The "--keep-going" option can also be quite useful when running datasets that don't necessarily meet the expected setup of files (multiple replicates, multiple time point), like public data downloaded from GEO.

There is a "--notemp" option which you can use if you want to keep temporary files usually deleted during the running of the pipeline, however be sure that you have a lot of storage space available as it will keep ALL the files (filtered FASTQ, SAM, BAM, BED of mapping...).

# Cluster usage 

If you want to run this on a cluster that uses SLURM (like GenoToul), you can use the run_snakemake_slurm.sh script as a template (it is meant to be run using sbatch). If you're not using GenoToul, you'll probably need to adjust quite a few of the parametres and maybe load the tools differently (GenoToul uses modules).

Just unzip this on your server, edit run_snakemake_slurm.sh (needs at least your username), check which rule you want to run, and then you should be ready to use:

`sbatch run_snakemake_slurm`

This will run the rule specified in the script. If you want to run a different rule, you need to edit that script. You'll also see a bunch of other options appended to the command line. Feel free to edit those at your own risk.

# Parameters 

A config.yaml file should be present in the directory in which you unzipped this tarball. It already contains a few parameters required for the pipeline to run, like the path to the genome for alignment.

You can also add other parameters to it to modify their values in the rules. The naming convention for these are {rule_name}_{parameter_name}. For example, "deeptools_bamCoverage_RPGC_se_bs" defines the "bs" parameter (bin size for the final BigWig) for the job "deeptools_bamCoverage_RPGC_se" (which runs the deeptools bamCoverage tool on a single-end alignment file).

To know which parameters you can set, you'll need to look in the Snakefile. It should however be quite easy to use CTRL + F or grep to find if a parameter is editable by following this naming convention.

In the config file, simply include "deeptools_bamCoverage_RPGC_se_bs: 10" to change the bin size used. You need to include this without any leading spaces or tabs, or the YAML syntax will consider it to be a dependancy of another element. 

There are some additional rules in the Snakefile which require using the configuration file to run (like "align_fastq"). For these, the names of the files you want to process need to be given in list form under samples -> fastq or samples -> peaks. To do so, write them like this:
```
samples:
  fastq:
    - test_data_chr20/CTCF_D1_1.filtered
    - test_data_chr20/CTCF_D1_2.filtered
```
I would recommend reading through the Snakemake documentation and the provided Snakefile a bit more to fully understand what these rules do. 