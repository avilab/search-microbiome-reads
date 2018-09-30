
library(tidyverse)
library(entrezquery)

q <- "shotgun AND illumina AND gut AND human AND (metagenome OR microbiome)"
pm <- entrez_docsums(query = q, db = "sra", retmax = 17000)

pm  <- mutate(pm, ExpXml = map(ExpXml, fix_xml),
              Runs = map(Runs, fix_xml))

write_rds(pm, glue::glue("output/metagenome_query_{Sys.Date()}.rds"))

