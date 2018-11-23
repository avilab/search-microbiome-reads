
import os.path
import pandas as pd
from snakemake.remote.FTP import RemoteProvider as FTPRemoteProvider

configfile: "config.yaml"
SAMPLES = pd.read_table("samples.tsv", sep = "\t", index_col = "sample")
FTP = FTPRemoteProvider(username = config["username"], password = config["password"])

SAMPLE = 'SRR5579958'

def get_fastq(wildcards):
  urls = SAMPLES.loc[wildcards.sample, ['fq1', 'fq2']]
  return list(urls)

rule all:
  input: expand("test/{sample}_{n}.fq.gz", sample = SAMPLE, n = [1, 2])
    
rule fastp:
  input:
    lambda wildcards: FTP.remote(get_fastq(wildcards))
  output:
    "test/{sample}_1.fq.gz", "test/{sample}_2.fq.gz"
  shell:
    """
    cp {input} {output}
    """
