
import os.path
import pandas as pd
from snakemake.remote.FTP import RemoteProvider as FTPRemoteProvider

config = "config.yml"
FTP = FTPRemoteProvider(username = "anonymous", password = "taavi.pall@ut.ee")

SAMPLES = 'SRR5713952'

def get_fastq_ftp(wildcards, path):
  runs = pd.read_table(path, sep = "\t", index_col = "sample")
  urls = runs.loc[wildcards.sample, ['fq1', 'fq2']]
  return list(urls)

rule all:
  input: expand("munge/{sample}_pair{n}_trimmed.gz", sample = SAMPLES, n = [1, 2])
    
rule fastp:
    input:
      lambda wildcards: FTP.remote(get_fastq_ftp(wildcards, "samples.tsv"))
    output:
      pair1 = "munge/{sample}_pair1_trimmed.fq.gz",
      pair2 = "munge/{sample}_pair2_trimmed.fq.gz",
      html = "munge/{sample}_fastp_report.html",
      json = "munge/{sample}_fastp_report.json"
    params:
      thresh = config['downsample']['count_thresh'],
      seed = config['downsample']['seed'],
      fastp = "--trim_front1 5 --trim_tail1 5 --length_required 50 --low_complexity_filter --complexity_threshold 8"
    threads: 8
    conda:
      "envs/fastp.yml"
    script:
      "qc.py"
