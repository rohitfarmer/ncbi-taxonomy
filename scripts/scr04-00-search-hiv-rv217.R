# Search organisims in hiv-rv217 study agains the local taxonomy database

library(tidyverse)
library(arrow)
library(doMC)
cores <- detectCores(all.tests = FALSE, logical = FALSE)
fs <- list.files(file.path("results", "hiv-rv217"), pattern = ".csv")

tax_name_out <- c()
for(i in 1:length(fs)){
        dat <- read_csv(file.path("results" ,"hiv-rv217", fs[[i]]), show_col_type = FALSE) %>%
                dplyr::pull(`Taxon Name`)
        tax_name_out <- append(tax_name_out, dat)
}

tax_name_out <- unique(tax_name_out)


# Load rankedlineage and names database


ranklin <- read_feather(file.path("results", "rankedlineage.feather"))
#name <- read_feather(file.path("results", "names.feather"))
name <- read_feather("https://zenodo.org/records/10672196/files/names.feather?download=1")

df_out <- tibble()
registerDoMC(cores)
df_out <- foreach(i = 1:length(tax_name_out), .combine = bind_rows) %dopar%{
        tax <- tax_name_out[[i]]
        cat(i, tax, "\n")
        taxid <- name %>% dplyr::filter(name_txt == tax) %>%
                pull(tax_id)
        if(length(taxid) !=0){
                ranklin %>% dplyr::filter(tax_id == taxid) %>%
                        dplyr::mutate("query" = tax)
        }
}

write_tsv(df_out, file.path("results", "hiv-rv217", "tax-levels-v2.tsv"))

not_found <- setdiff(tax_name_out, df_out$tax_name)

library("taxize")

fetch_tax_levels <- function(all_taxa, output_dir){
  df_error_out <- tibble()
  for(i in 1:length(all_taxa)){
    tax <- all_taxa[i]
    tax_record <- try(classification(tax, db = "ncbi", max_tries = 10))
    
    if (inherits(tax_record, "try-error")) {                                                                                                                                                            
      cat("Error:", i, ":", tax, "\n")      
      df_error_out <- bind_rows(df_error_out,                                                                                                                                             
                                tibble("Taxon Name" = tax)) 
    } else {  
      temp_df <- bind_cols("query" = tax, tax_record[[1]])
      file_name <- paste0(tax, ".feather")
      file_name <- str_replace_all(file_name,"\\/","--")
      write_feather(temp_df, file.path(output_dir, file_name))
    }
  }
  return(df_error_out)
}

output_dir <- file.path("results", "hiv-rv217", "taxize-levels-v2")
dir.create(output_dir, recursive = TRUE)
df_error_out <- fetch_tax_levels(not_found, output_dir) 




