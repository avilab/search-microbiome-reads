#'---
#' author: "Taavi Päll"
#' date: "2018-10-01"
#' output: github_document
#' always_allow_html: yes
#'---

library(tidyverse)

#' Check if we already have query data available.

if (file.exists("output/PRJNA361402_query_2018-10-02.csv")) {
  prj_wgs <- read_csv("output/PRJNA361402_query_2018-10-02.csv")
} else {
  library(xml2)
  library(XML)
  source("R/sra_xml_parsers.R")
  
  q <- "PRJNA361402"
  prj <- entrezquery::entrez_docsums(query = q, db = "sra", retmax = 1000)
  prj_fixed  <- mutate(prj, ExpXml = map(ExpXml, fix_xml),
                       Runs = map(Runs, fix_xml))
  
  parse_expxml_safely <- safely(parse_expxml, quiet = FALSE)
  parse_runs_xml_safely <- safely(parse_runs_xml, quiet = FALSE)
  
  prj_parsed  <- prj_fixed %>% 
    mutate(ExpXml = map2(ExpXml, Id, parse_expxml_safely),
           Runs = map(Runs, parse_runs_xml_safely))
  prj_parsed <- prj_parsed %>% mutate_at(vars(ExpXml, Runs), map, "result")
  sets_with_probs <- filter(prj_parsed, map_lgl(ExpXml, is.null) | map_lgl(Runs, is.null))
  sets_ok <- filter(prj_parsed, !map_lgl(ExpXml, is.null), !map_lgl(Runs, is.null))
  sets_unnested <- unnest(sets_ok)
  results_wgs <- filter(sets_unnested, library_strategy == "WGS")
  write_csv(results_wgs, glue::glue("output/PRJNA361402_query_{Sys.Date()}.csv"))
}

knitr::kable(head(prj_wgs)) %>% 
  kableExtra::kable_styling()

prj_wgs
length(unique(prj_wgs$Experiment_name))
length(unique(prj_wgs$Biosample))
