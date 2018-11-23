
import os.path
import pandas as pd
from snakemake.remote.FTP import RemoteProvider as FTPRemoteProvider

configfile: "config.yaml"
RUNS = pd.read_table("samples.tsv", sep = "\t", index_col = "sample")
FTP = FTPRemoteProvider(username = config["username"], password = config["password"])

SAMPLES = 'SRR5713952'

def get_fastq(wildcards):
  urls = RUNS.loc[wildcards.sample, ['fq1', 'fq2']]
  return list(urls)

rule all:
  input: expand("munge/{sample}_pair{n}_trimmed.fq.gz", sample = SAMPLES, n = [1, 2])
    
rule fastp:
    input:
      lambda wildcards: get_fastq(wildcards)
    output:
      pair1 = "munge/{sample}_pair1_trimmed.fq.gz",
      pair2 = "munge/{sample}_pair2_trimmed.fq.gz",
      html = "munge/{sample}_fastp_report.html",
      json = "munge/{sample}_fastp_report.json",
      sub1 = temp("munge/{sample}_sub1.fq.gz"),
      sub2 = temp("munge/{sample}_sub2.fq.gz")
    params:
      frac = lambda wildcards: downsample(wildcards),
      seed = config["seed"],
      fastp = "--trim_front1 5 --trim_tail1 5 --length_required 50 --low_complexity_filter --complexity_threshold 8"
    threads: 8
    log: "logs/{sample}_fastp.log"
    conda:
      "envs/fastp.yml"
    shell:
      """
      if (( $(echo "{params.frac} > 0" | bc) )) && (( $(echo "{params.frac} < 1" | bc) )) ; then
        seqtk sample -s{params.seed} {input[0]} {params.frac} > {output.sub1}
        seqtk sample -s{params.seed} {input[1]} {params.frac} > {output.sub2}
      else
        ln -sr {input[0]} {output.sub1}
        ln -sr {input[1]} {output.sub2}
      fi
      fastp -i {output.sub1} -I {output.sub2} \
            -o {output.pair1} -O {output.pair2} {params.fastp} \
            -h {output.html} -j {output.json} \
            -w {threads} > {log} 2>&1
      """
