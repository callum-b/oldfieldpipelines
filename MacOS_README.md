This is for users of C BURNARD's Snakemake pipeline who happen to have a Mac. Please also read the default README file, as it will explain the concept a bit more. This is mainly for miniconda installation.

## Step 1: Install Miniconda (if not already installed)

Open your browser and go to: https://docs.conda.io/en/latest/miniconda.html

Download the Miniconda installer for macOS (Apple M1/M2 or Intel) — choose the right one for your machine.

Open Terminal (search “Terminal” in Spotlight).

Run the downloaded installer, something like:

bash ~/Downloads/Miniconda3-latest-MacOSX-arm64.sh

Follow the prompts and say yes to adding it to your PATH.

Close and reopen the Terminal.

## Step 2: Create the Environment

In Terminal, run the following commands:

cd /path/to/oldfieldpiepelines   # Navigate to your project folder

conda env create -f miniconda_smk_chipseq.yaml

OR if you're having issues with the YAML file format:
```
# Step 1: Create the environment
conda create -n smk_chipseq python=3.10.14 -y

# Step 2: Activate the environment
conda activate smk_chipseq

# Step 3: Add necessary channels (if not already configured)
conda config --add channels conda-forge
conda config --add channels bioconda

# Step 4: Install dependencies
conda install -y \
  pysam=0.22 \
  macs3=3.0.1 \
  deeptools=3.5.5 \
  snakemake=7.32.4 \
  matplotlib=3.8.4 \
  samtools=1.20 \
  bowtie2=2.5.4 \
  fastqc=0.12.1 \
  jinja2=3.1.4 \
  graphviz=0.11 \
  pulp=2.7 \
  pygments=2.15.1 \
  bedtools=2.31.1 \
  multiqc=1.28

```
This installs all necessary tools into a named environment called smk_chipseq.


## Step 3: Activate the Environment

Once the install is complete:

conda activate smk_chipseq

You’ll now see (smk_chipseq) at the start of your terminal prompt, which means you're using the correct tools.


## Step 4: Navigate to and run the Snakemake Pipeline

cd ChIPseq

(prepare data as needed to run the pipeline)

snakemake -np andold_autodetect
snakemake --cores 4 andold_autodetect

Adjust the --cores number depending on how many CPU cores you want to use.
