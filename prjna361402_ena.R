library(httr)
library(tidyverse)
library(xml2)

study_xml_url <- "https://www.ebi.ac.uk/ena/data/view/{study}&display=xml&download=xml&filename={study}.xml"
bioproject <- "PRJNA361402"
study <- "SRP100518"

url <- glue::glue(study_xml_url)
resp <- GET(url)
content(resp, as = "text") %>% 
  read_xml() %>%
  XML::xmlTreeParse()


fq <- GET("http://www.ebi.ac.uk/ena/data/warehouse/filereport?accession=SRP100518&result=read_run&fields=run_accession,fastq_ftp,fastq_md5,fastq_bytes")
fq_ftp <- content(fq, encoding = "UTF8") %>% read_delim(delim = "\t")
fq_ftp
