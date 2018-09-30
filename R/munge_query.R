
library(tidyverse)
library(xml2)
library(XML)
source("R/sra_xml_parsers.R")

pm <- read_rds("output/metagenome_query_2018-09-30.rds")
pm_parsed  <- mutate(pm, ExpXml = map(ExpXml, parse_expxml),
                     Runs = map(Runs, parse_runs_xml))

unnest(pm_parsed)
