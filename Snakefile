__author__ = "Taavi Päll"
__copyright__ = "Copyright 2018, Avilab"
__email__ = "taavi.pall@ut.ee"
__license__ = "MIT"

import os.path
import pandas as pd

runs = pd.read_table("ena_samples.tsv", sep = "\s+", index_col = "sample", dtype = str)
SAMPLES = runs.index.values.tolist()

def get_fastq_path(wildcards, fasp_url = 'fasp_fq1'):
  url = runs.loc[wildcards.sample, [fasp_url]].dropna()[0]
  return os.path.dirname(url) 

wildcard_constraints:
    sample="[^/_]+"

rule all:
  input: expand("{sample}", sample = SAMPLES)

rule download:
    input:
      lambda wildcards: get_fastq_path(wildcards, 'fasp_fq1')
    output:
      directory("{sample}")
    params:
      "-QT -l 300m -P33001 -i $HOME/.aspera/connect/etc/asperaweb_id_dsa.openssh"
    shell:
      """
      $HOME/.aspera/connect/bin/ascp {params} era-fasp@{input} .
      """
