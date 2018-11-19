library(httr)
library(tidyverse)
library(xml2)
library(glue)
library(readxl)

project <- "PRJNA361402"
study <- "SRP100518"

#' Retrieve fastq file info and urls
fq <- GET(glue("http://www.ebi.ac.uk/ena/data/warehouse/filereport?accession={study}&result=read_run"))
fq_ftp <- content(fq, encoding = "UTF-8") %>% read_delim(delim = "\t")

samples <- select(fq_ftp, experiment_title, run_accession, library_name, read_count, base_count, fastq_bytes, fastq_md5, fastq_ftp)

ftp_paths <- samples %>% 
  separate(fastq_ftp, into = c("fq1", "fq2"), sep = ";") %>% 
  separate(fastq_bytes, into = c("fq1_bytes", "fq2_bytes"), sep = ";") %>%
  separate(fastq_md5, into = c("fq1_md5", "fq2_md5"), sep = ";") %>% 
  rename(sample = run_accession)
 
write_delim(ftp_paths, "samples_remote.tsv", delim = "\t")

select(ftp_paths, "sample", "fq1", "fq2")

#' Runs and samples
url <- glue("https://www.ebi.ac.uk/ena/data/view/{project}&portal=read_run&display=xml")
resp <- GET(url)
read_run <- content(resp, encoding = "UTF-8")
contents <- read_run %>% 
  read_xml() %>% 
  xml_contents()

run_df <- contents %>% 
  xml_attrs() %>% 
  do.call(rbind, .) %>% 
  as_data_frame()

run_df$title <- contents %>% 
  xml_find_first("TITLE") %>% 
  xml_text()
acc_sample <- separate(run_df, title, c("title", "sample"), sep = "; ") %>% 
  select(run_accession = accession, sample)

#' Treatments come from Supplement2 of https://www.nature.com/articles/nm.4345
if (!file.exists("data/nm.4345-S3.xlsx")) {
  supp2_url <- "https://media.nature.com/original/nature-assets/nm/journal/v23/n7/extref/nm.4345-S3.xlsx"
  download.file(supp2_url, "data/nm.4345-S3.xlsx")
}

supp2 <- read_excel("data/nm.4345-S3.xlsx", range = "A4:N134", col_names = FALSE)
col_names <- read_excel("data/nm.4345-S3.xlsx", range = "A2:N2")
colnames(supp2) <- colnames(col_names)
treatments <- select(supp2, Sample, Treatment) %>% 
  rename_all(str_to_lower)
treatments <- left_join(treatments, acc_sample) %>% 
  select(run_accession, everything())
aspera <- left_join(treatments, fq_ftp) %>% 
  select(run_accession:treatment, fastq_aspera) %>% 
  separate(fastq_aspera, c("fasp_fq1", "fasp_fq2"), sep = ";") %>% 
  mutate(fq1 = basename(fasp_fq1),
         fq2 = basename(fasp_fq2)) %>% 
  select(sample_id = sample, treatment, sample = run_accession, fq1, fq2, everything())

#' Make smaller subset for testing
id <- c("10V", "11V", "12V", "13V", "20V", "26V")
samps <- filter(aspera, str_detect(sample_id, paste0(id, collapse = "|")))

#' Check if target dir exists and if not create 
path <- glue("~/fastq/{str_to_lower(project)}")
if (!dir.exists(path)) dir.create(path)

#' Write to file
write_tsv(samps, file.path(path, "ena_samples.tsv"))
