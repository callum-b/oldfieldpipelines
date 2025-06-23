This is for users of C BURNARD's Snakemake pipeline who happen to have a Mac. Please also read the default README file, as it will explain the concept a bit more. This is mainly for miniconda installation.

## Step 1: Install Miniconda (if not already installed)

Open your browser and go to: https://www.anaconda.com/docs/getting-started/miniconda/install#mac-os and scroll down to "Quickstart install instructions"

Open Terminal (search “Terminal” in Spotlight).

Copy and paste the installation code (watch out, there should be two options: Apple Silicon or Intel, depending on the hardware of your Mac. If your Mac is M1/M2 then choose Apple Silicon, otherwise look it up.)

Be sure to run the "source" command after the main block of code in that section, it shows your computer where to find the program you just installed! (You may need to run that each time you want to activate the environment, still investigating this issue)

Close and reopen the Terminal.

## Step 2: Create the Environment

In Terminal, run the following commands:

cd /path/to/oldfieldpipelines   # Navigate to your project folder

conda env create -f miniconda_smk_chipseq.yaml

OR if you're having issues with the YAML file format:
```
# Process recap:
# Step 1: Create the environment
# Step 2: Activate the environment
# Step 3: Add necessary channels (if not already configured)
# Step 4: Install dependencies
# Step 5: Install problematic dependencies with pip


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


## Step 3: Activate the Environment

Once the install is complete:

conda activate smk_chipseq

And to exit the environment:

conda deactivate

You’ll now see (smk_chipseq) at the start of your terminal prompt, which means you're using the correct tools.


## Step 4: Navigate to and run the Snakemake Pipeline

cd ChIPseq

(prepare data as needed to run the pipeline)

snakemake -np andold_autodetect
snakemake --cores 4 andold_autodetect

Adjust the --cores number depending on how many CPU cores you want to use.
