
library(tidyverse)
library(skimr)
result <- read_csv("output/metagenome_query_2018-09-30.csv")
skim(result)
result <- mutate(result, Experiment_name = str_replace_all(Experiment_name, "\"", ""))

result_selected <- select(result, which(!near(summarise_all(result, n_distinct), 1)))
results_wgs <- filter(result_selected, library_strategy == "WGS")
results_wgs_paired <- filter(results_wgs, library_layout == "PAIRED")

ggplot(data = result_selected) +
  geom_histogram(mapping = aes(x = CreateDate), bins = 30) +
  facet_wrap(~library_layout)

