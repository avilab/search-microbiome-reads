
__author__ = "Taavi Päll"
__copyright__ = "Copyright 2018, Avilab"
__email__ = "taavi.pall@ut.ee"
__license__ = "MIT"

# Load libraries
import os.path
import pandas as pd

# Load sample and path info
runs = pd.read_table("samples.tsv", sep = "\s+", index_col = "run_accession", dtype = str)
RUNS = runs.index.values.tolist()

list(runs['fq1']) + list(runs['fq2'])

# Target rule
rule all:
    input:
      expand("{run}_{pair}.fastq.gz", run = RUNS, pair = [1, 2])

# Rules
def get_fastq_path(wildcards, read_pair = 'fq1'):
 return os.path.dirname(runs.loc[wildcards.run, [read_pair]].dropna()[0])

rule download:
    input:
      lambda wildcards: get_fastq_path(wildcards, 'fq1')
    output:
      expand("{run}_{pair}.fastq.gz", run = RUNS, pair = [1, 2])
    params:
      "-QT -l 300m -P33001 -i ~/.aspera/connect/etc/asperaweb_id_dsa.openssh"
    shell:
      """
      ascp {params} era-fasp@{input} .
      
      """
 
