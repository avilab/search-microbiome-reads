library(httr)
library(glue)
library(dplyr)
library(tidyr)
library(purrr)
library(readr)

# ZENODO_PAT was set in .Renviron
zenodo_get <- function(path) {
    GET('https://zenodo.org', 
        query = list(access_token = Sys.getenv("ZENODO_PAT")),
        path = path)
}

path <- "api/deposit/depositions"
r <- zenodo_get(path)
cont <- content(r)
record_id <- cont[[2]]$record_id

path <- glue("api/deposit/depositions/{record_id}")
r <- zenodo_get(path)
cont <- content(r)
files <- cont$files
files <- do.call(rbind, files)
as_data_frame(files[,1:4]) %>% unnest()
files_unnested <- as_data_frame(files) %>% 
    unnest(checksum) %>% 
    unnest(filename) %>% 
    unnest(filesize) %>% 
    unnest(id) %>% 
    mutate(download = map_chr(links, "download"),
           self = map_chr(links, "self")) %>% 
    select(-links, -self)
write_csv(files_unnested, "output/zenodo_download_links.csv")
