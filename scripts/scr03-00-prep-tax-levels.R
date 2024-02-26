# Prepare taxonomy level database

library(tidyverse)
library(arrow)

# Process rankedlineage
# sed -i 's/\t//g' rankedlineage.dmp # search and replace all tabs first
rankedlineage <- read.table(file.path("data", "new_taxdump", "rankedlineage.dmp"), 
           sep = "|", nrows = -1, fill = TRUE, quote = "")

rankedlineage <- rankedlineage %>% dplyr::select(-V11) %>%
        tibble()
colnames(rankedlineage) <-  c("tax_id", "tax_name", "species", "genus","family","order","class","phylum","kingdom","superkingdom")

write_feather(rankedlineage, file.path("results", "rankedlineage.feather"))

# Process names
# sed 's/\t//g' names.dmp > names.txt # search and replace all tabs first
df_names <- read.table(file.path("data", "new_taxdump", "names.txt"),
                       sep = "|", fill = TRUE, quote = "") %>%
        tibble()

df_names <- df_names %>% dplyr::select(-V5) %>%
        set_names(c("tax_id", "name_txt", "unique_name", "name_class"))

write_feather(df_names, file.path("results", "names.feather"))

