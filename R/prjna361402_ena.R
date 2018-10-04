library(httr)
library(tidyverse)
library(xml2)
library(glue)
library(readxl)

project <- "PRJNA361402"
study <- "SRP100518"

#' retrieve fastq file info and urls
fq <- GET(glue("http://www.ebi.ac.uk/ena/data/warehouse/filereport?accession={study}&result=read_run"))
fq_ftp <- content(fq, encoding = "UTF8") %>% 
  read_delim(delim = "\t")

#' Runs and samples
url <- glue("https://www.ebi.ac.uk/ena/data/view/{project}&portal=read_run&display=xml")
resp <- GET(url)
read_run <- content(resp, encoding = "UTF8")
contents <- read_run %>% 
  read_xml() %>% 
  xml_contents()

run_df <- contents %>% 
  xml_attrs() %>% 
  rbind_list()
run_df$title <- contents %>% xml_find_first("TITLE") %>% 
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
  select(run_accession:treatment, fastq_aspera)

samps <- filter(aspera, str_detect(sample, "10V"))
samps$fastq_aspera[1]
