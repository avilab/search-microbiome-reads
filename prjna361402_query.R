
library(httr)
library(rvest)
search <- GET("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=sra&term=PRJNA361402&retmax=1000&usehistory=y")

conts <- content(search)
web <- xml_find_first(conts, "WebEnv") %>% xml_text()
key <- xml_find_first(conts, "QueryKey") %>% xml_text()

fetch <- GET(glue::glue("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=sra&query_key={key}&WebEnv={web}"))
fetched_contents <- content(fetch)
fechild <- xml_children(fetched_contents)
fechild[[1]] %>% xml_find_first("SAMPLE/SAMPLE_ATTRIBUTES") %>% xml_text()


res <- GET("http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&db=sra&rettype=runinfo&term=PRJNA361402")
runinfo <- content(res, as = "text", encoding = "UTF8")
read_csv(runinfo) %>% 
  DT::datatable()
