
samples <- read_tsv("output/samples.tsv")
sampsize <- select(fq_ftp, experiment_title, sample = run_accession, fastq_bytes, read_count) %>% 
  separate(fastq_bytes, into = c("fq1_bytes", "fq2_bytes"), sep = ";") %>% 
  separate(experiment_title, into = c("platform", "biosample"), sep = "; ") %>% 
  select(-platform)
filter(sampsize, sample == "SRR5713949")

my_sampsize <- inner_join(samples, sampsize) %>% 
  mutate_at(vars(ends_with("bytes")), ~ parse_number(.x) / (1024^2)) %>% 
  arrange(desc(fq1_bytes))
samp_sum <- summarise_at(my_sampsize, vars(fq1_bytes, read_count), funs(min, median, mad, max))

threshold <- samp_sum$read_count_median + (2 * samp_sum$read_count_mad)

p <- ggplot(mapping = aes(read_count)) +
  geom_histogram(data = my_sampsize, binwidth = 1e6) +
  geom_vline(xintercept = samp_sum$read_count_median, linetype = "dashed") +
  geom_vline(xintercept = threshold, linetype = "dotted")
p

normalised_counts <- filter(my_sampsize, read_count > threshold) %>% 
  mutate(perc = round(samp_sum$read_count_median / read_count, 2),
         read_count = read_count * perc)

p + geom_histogram(data = normalised_counts, fill = "red", binwidth = 1e6)

my_sampsize %>% 
  group_by(biosample) %>% 
  summarise_at(vars(ends_with("bytes"), read_count), sum)

ggplot() +
  geom_point(data = my_sampsize, mapping = aes(x = read_count, fq1_bytes))
