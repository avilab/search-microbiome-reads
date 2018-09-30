
fix_xml <- function(x) {
  read_xml(paste("<document>", x, "</document>"))
}

parse_expxml <- function(xml) {
  children <- xml %>% xml_children()
  child_names <- xml_name(children)
  child_attrs <- xml_attrs(children)
  names(child_attrs) <- child_names
  
  non_empty <- map_lgl(child_attrs, ~length(.x) == 0)
  
  library_descriptor_nodes <- list("LIBRARY_NAME", 
                                   "LIBRARY_STRATEGY", 
                                   "LIBRARY_SOURCE", 
                                   "LIBRARY_SELECTION")
  
  library_layout <- data_frame(node = str_to_lower("LIBRARY_LAYOUT"), value = xml_find_first(xml, "/document//Library_descriptor/LIBRARY_LAYOUT") %>% 
                                 xml_contents() %>% 
                                 xml_name())
  
  library_descriptor <- data_frame(node = str_to_lower(library_descriptor_nodes), 
                                   value = map_chr(library_descriptor_nodes, 
                                                   ~xml_text(xml_contents(xml_find_first(xml, str_c("/document//Library_descriptor/", .x)))))) %>% 
    bind_rows(library_layout)
  
  Bioproject <- xml_find_first(xml, "/document//Bioproject")
  Biosample <- xml_find_first(xml, "/document//Biosample")
  
  data_frame(node = xml_name(children[!non_empty]), 
             data = map(child_attrs[!non_empty], 
                        ~data_frame(attr = names(.x), 
                                    value = .x))) %>% 
    unnest() %>% 
    bind_rows(library_descriptor) %>%
    bind_rows(data_frame(node = xml_name(Bioproject), 
                         attr = NA, 
                         value = xml_text(Bioproject))) %>% 
    bind_rows(data_frame(node = xml_name(Biosample), 
                         attr = NA, 
                         value = xml_text(Biosample))) %>% 
    unite(key, node, attr) %>% 
    spread(key, value) %>% 
    rename_all(~str_replace(.x, "_NA$", ""))
}

parse_runs_xml <- function(runs) {
  runs <- xml_contents(runs)
  child_names <- xml_name(runs)
  child_attrs <- xml_attrs(runs)
  names(child_attrs) <- child_names
  data_frame(node = child_names, 
             data = map(child_attrs, ~data_frame(attr = names(.x), value = .x))) %>% 
    unnest() %>% 
    unite(key, node, attr) %>% 
    spread(key, value)
}

