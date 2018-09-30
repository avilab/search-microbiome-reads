
library(tidyverse)
library(entrezquery)
library(xml2)
library(XML)
source("R/sra_xml_parsers.R")

q <- "shotgun AND illumina AND gut AND human AND (metagenome OR microbiome)"
pm <- entrez_docsums(query = q, db = "sra", retmax = 17000)

pm_fixed  <- mutate(pm, ExpXml = map(ExpXml, fix_xml),
              Runs = map(Runs, fix_xml))

parse_expxml_safely <- safely(parse_expxml, quiet = FALSE)
parse_runs_xml_safely <- safely(parse_runs_xml, quiet = FALSE)

pm_parsed  <- pm_fixed %>% 
  mutate(ExpXml = map2(ExpXml, Id, parse_expxml_safely),
         Runs = map(Runs, parse_runs_xml_safely))

pm_parsed <- pm_parsed %>% mutate_at(vars(ExpXml, Runs), map, "result")
sets_with_probs <- filter(pm_parsed, map_lgl(ExpXml, is.null) | map_lgl(Runs, is.null))
sets_ok <- filter(pm_parsed, !map_lgl(ExpXml, is.null), !map_lgl(Runs, is.null))
sets_unnested <- unnest(sets_ok)

write_csv(sets_unnested, glue::glue("output/metagenome_query_{Sys.Date()}.csv"))
write_rds(sets_with_probs, glue::glue("output/metagenome_query_runs_or_expxml_missing_{Sys.Date()}.rds"))
