library(tidyverse)

#' samples_remote.tsv was generated using R/prjna361402_ena.R
samples <- read_tsv("output/samples_remote.tsv")

my_sampsize <- samples %>% 
  mutate_at(vars(ends_with("bytes")), ~ parse_number(.x) / (1024^2)) %>% 
  arrange(desc(fq1_bytes))
samp_sum <- summarise_at(my_sampsize, vars(fq1_bytes, read_count), funs(min, median, mad, max))

threshold <- samp_sum$read_count_median + (3 * samp_sum$read_count_mad)

p <- ggplot(mapping = aes(read_count)) +
  geom_histogram(data = my_sampsize, binwidth = 1e6) +
  geom_vline(xintercept = samp_sum$read_count_median, linetype = "dashed") +
  geom_vline(xintercept = threshold, linetype = "dotted")
p

normalised_counts <- my_sampsize %>% 
  mutate(perc = if_else(read_count > threshold, round(samp_sum$read_count_median / read_count, 2), 1),
         read_count_perc = ceiling(read_count * perc))

ggplot(data = normalised_counts) + 
  geom_histogram(mapping = aes(x = read_count_perc))

(sum_sampsize <- my_sampsize %>% 
  group_by(bio_replica) %>% 
  summarise_at(vars(ends_with("bytes"), starts_with("read_count")), sum))

(count_reps <- my_sampsize %>% 
    group_by(bio_replica) %>% 
    count())

sum_sampsize <- left_join(sum_sampsize, count_reps)

ggplot() +
  geom_point(data = my_sampsize, mapping = aes(x = read_count, fq1_bytes))


(sum_sampsize <- normalised_counts %>% 
    group_by(bio_replica) %>% 
    summarise_at(vars(ends_with("bytes"), starts_with("read_count")), sum))

(count_reps <- normalised_counts %>% 
    group_by(bio_replica) %>% 
    count())

ungroup(count_reps) %>% 
  group_by(n) %>% 
  count()

sum_sampsize <- left_join(sum_sampsize, count_reps)

ggplot(data = sum_sampsize) +
  geom_histogram(mapping = aes(x = read_count_perc), binwidth = 1e6)

sum_sampsize %>% 
  arrange(desc(read_count_perc))

#' Select from each biological replicate max five runs
set.seed(10)
norm_counts_five <- normalised_counts %>% 
  group_by(bio_replica) %>% 
  sample_n(5) %>% 
  mutate(analyse = TRUE)

anti_join(normalised_counts, norm_counts_five) %>% 
  mutate(analyse = FALSE) %>% 
  bind_rows(norm_counts_five) %>% 
  arrange(sample) %>% 
  write_tsv("output/samples_norm.tsv")

(sum_sampsize <- norm_counts_five %>% 
    group_by(bio_replica) %>% 
    summarise_at(vars(ends_with("bytes"), starts_with("read_count")), sum))

(count_reps <- norm_counts_five %>% 
    group_by(bio_replica) %>% 
    count())

sum_sampsize <- left_join(sum_sampsize, count_reps)

ggplot(data = sum_sampsize) +
  geom_histogram(mapping = aes(x = read_count_perc), binwidth = 2.5e5)

  
  
