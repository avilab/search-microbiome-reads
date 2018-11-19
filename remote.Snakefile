
import os.path
import pandas as pd
from snakemake.remote.FTP import RemoteProvider as FTPRemoteProvider

runs = pd.read_table("samples_remote.tsv", sep = "\t", index_col = "sample")
SAMPLES = 'SRR5713952'

FTP = FTPRemoteProvider(username="anonymous", password="taavi.pall@ut.ee")

def get_fastq_ftp(wildcards, ftp_url = ['fq1', 'fq2']):
  urls = runs.loc[wildcards.sample, ['fq1', 'fq2']]
  return list(urls)

rule all:
  input: expand("munge/{sample}_pair{n}_trimmed.gz", sample = SAMPLES, n = [1, 2])
    
rule fastp:
    input:
      FTP.remote(get_fastq_ftp(wildcards))
    output:
      pair1 = "munge/{sample}_pair1_trimmed.gz",
      pair2 = "munge/{sample}_pair2_trimmed.gz",
      html = "munge/{sample}_fastp_report.html",
      json = "munge/{sample}_fastp_report.json"
    params:
      "-f 5 -t 5 -l 50 -y -Y 8"
    threads: 8
    conda:
      "../envs/fastp.yml"
    log: "logs/{sample}_fastp.log"
    shell:
      """
      fastp -i {input[0]} -I {input[1]} -o {output.pair1} -O {output.pair2} {params} -h {output.html} -j {output.json} -w {threads} > {log} 2>&1
      """
