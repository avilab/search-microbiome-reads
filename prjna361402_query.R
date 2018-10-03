library(httr)
library(rvest)
library(dplyr)
library(readr)
library(DT)

#' ### Create document summary table with Experiment_acc ids
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

#' ### Alternative search for Bioproject
search <- GET("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=sra&term=PRJNA361402&retmax=1000&usehistory=y")

#' Get search result WebEnv and QueryKey
conts <- content(search)
web <- xml_find_first(conts, "WebEnv") %>% xml_text()
key <- xml_find_first(conts, "QueryKey") %>% xml_text()

#' Fetch search results as xml
fetch <- GET(glue::glue("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=sra&query_key={key}&WebEnv={web}"))
fetched_contents <- content(fetch)
fechild <- xml_children(fetched_contents)

#' ### Fetch metadata with the SRA Run Info CGI in csv format
res <- GET("http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&db=sra&rettype=runinfo&term=PRJNA361402")
runinfo <- content(res, as = "text", encoding = "UTF8")
read_csv(runinfo) %>% 
  DT::datatable(data = .)
