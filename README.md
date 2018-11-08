# Search and download microbiome reads

## Install prerequisites
- If missing, download and install miniconda https://conda.io/docs/user-guide/install/index.html.
    - In case of Linux, following should work:
```
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

- Install Aspera Connect as described in https://github.com/aertslab/install_aspera_connect.
- Setup snakemake conda environment by running
```
conda env create -f envs/searchreads.yml
```

