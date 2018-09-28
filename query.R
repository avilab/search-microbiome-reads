
library(tidyverse)
library(xml2)
library(XML)
library(entrezquery)
q <- "shotgun AND illumina AND gut AND human AND (metagenome OR microbiome)"
pm <- entrez_docsums(query = q, db = "sra", retmax = 10)
pm

pm  <- mutate(pm, expxml = map(ExpXml, ~ read_xml(paste("<document>", .x, "</document>"))))

xml <- pm$expxml[[1]]

data_frame(node = , value = list(
  title = xml_find_first(xml, "/document//Summary/Title") %>% xml_text(),
  platform = xml_find_first(xml, "/document//Summary/Platform") %>% xml_text(),
  instrument_model = xml_find_first(xml, "/document//Summary/Platform") %>% xml_attrs()
)) %>% 
  unnest()


Bioproject <- xml_find_first(xml, "/document//Bioproject") 
Biosample <- xml_find_first(xml, "/document//Biosample")
data_frame(node = xml_name(Bioproject), attr = NA, value = xml_text(Bioproject))
data_frame(node = xml_name(Biosample), attr = NA, value = xml_text(Biosample))

  
children <- xml %>% xml_children() 
child_names <- xml_name(children)
child_attrs <- xml_attrs(children)
names(child_attrs) <- child_names

non_empty <- map_lgl(child_attrs, ~length(.x) == 0)

data_frame(node = xml_name(children[!non_empty]), data = map(child_attrs[!non_empty], ~data_frame(attr = names(.x), value = .x))) %>% 
  unnest()

list("LIBRARY_NAME", "LIBRARY_STRATEGY", "LIBRARY_SOURCE", "LIBRARY_SELECTION", "LIBRARY_LAYOUT") %>% 
  map(~xml_text(xml_contents(xml_find_first(xml, str_c("/document//Library_descriptor/", .x)))))

library_name <- xml_find_first(xml, "/document//Library_descriptor/LIBRARY_NAME") %>% 
  xml_contents() %>% 
  xml_text()
library_strategy <- xml_find_first(xml, "/document//Library_descriptor/LIBRARY_STRATEGY") %>% xml_text()
library_source <- xml_find_first(xml, "/document//Library_descriptor/LIBRARY_SOURCE") %>% xml_text()
library_selection <- xml_find_first(xml, "/document//Library_descriptor/LIBRARY_SELECTION") %>% xml_text()
library_layout <- xml_find_first(xml, "/document//Library_descriptor/LIBRARY_LAYOUT") %>% 
  xml_contents() %>% 
  xml_name()
