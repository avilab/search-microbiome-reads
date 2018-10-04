
library(tidyverse)
library(skimr)
result <- read_csv("output/metagenome_query_2018-09-30.csv")
skim(result)

result <- mutate(result, Experiment_name = str_replace_all(Experiment_name, "\"", ""))

result_selected <- select(result, which(!summarise_all(result, n_distinct) <= 1))
results_wgs <- filter(result_selected, library_strategy == "WGS")
results_wgs_paired <- filter(results_wgs, library_layout == "PAIRED")


#' Number of submitted samples
ggplot(data = result_selected) +
  geom_histogram(mapping = aes(x = CreateDate), bins = 30) +
  facet_wrap(~library_layout)

# Whoaa.., one project contributes most of the samples
results_wgs_paired %>% 
  group_by(Bioproject) %>% 
  summarise(N = n()) %>% 
  arrange(desc(N))

#' Number of bioprojects
result_selected %>% 
  group_by(Bioproject, library_layout) %>% 
  summarise(CreateDate = min(CreateDate)) %>% 
  ggplot() +
  geom_histogram(mapping = aes(x = CreateDate), bins = 10) +
  facet_wrap(~library_layout)

#' Number of spots per run
results_wgs_paired %>% 
  ggplot() +
  geom_histogram(aes(Run_total_spots), bins = 30) +
  scale_x_log10()

#' Filter by spots, remove samples with less than 1e5 spots
results_wgs_paired_filtered <- results_wgs_paired %>% 
  filter(Run_total_spots > 1e5)

skim(results_wgs_paired_filtered)

#' 
results_wgs_paired_filtered %>% 
  group_by(Bioproject) %>% 
  summarise(N = n()) %>% 
  arrange(desc(N))

prj <- filter(results_wgs_paired_filtered, Bioproject == "PRJNA290729")

library(httr)
library(xml2)

study_xml_url <- "https://www.ebi.ac.uk/ena/data/view/{study}&display=xml&download=xml&filename={study}.xml"
study <- unique(prj$Study_acc)

unique(prj$Bioproject)

url <- glue::glue(study_xml_url)
resp <- GET(url)
content(resp, as = "text") %>% 
  read_xml() %>%
  XML::xmlTreeParse()


warehouse_url <- glue::glue("http://www.ebi.ac.uk/ena/data/warehouse/filereport?accession={study}&result=read_run&fields=run_accession,fastq_ftp,fastq_md5,fastq_bytes")
fq <- GET(warehouse_url)
fq_ftp <- content(fq, encoding = "UTF8") %>% read_delim(delim = "\t")
fq_ftp


