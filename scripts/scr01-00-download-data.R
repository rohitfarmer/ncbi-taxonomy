# Download and decompress accession to taxid files from the ncbi ftp side.
# Concatenate all the files in a feather file.

library(RCurl)
library(XML)
library(tidyverse)
library(arrow)
library(RSQLite)


# Define output folders
download_dir <- file.path("data", "accession-to-tax")
dir.create(download_dir, recursive = TRUE)

decompress_dir <- file.path("results", "accession-to-taxid")
dir.create(decompress_dir, recursive = TRUE)


stop()
# Define the URL of the FTP site
url <- "https://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/"

# Fetch the content
content <- getURL(url, .opts = list(ftp.use.epsv = FALSE, ssl.verifypeer = FALSE))

# Parse the HTML content
doc <- htmlParse(content)

# Extract the links
links <- xpathSApply(doc, "//a", xmlGetAttr, "href")

# Filter out parent directory link and print the files and their links
files <- links[links != "../"]
file_links <- paste0(url, files)

# Filter the file names and make a final list of files to download
files_to_download <- tibble(files, file_links) %>%
        dplyr::filter(startsWith(files, "prot.accession2taxid.") |
                      startsWith(files, "pdb.accession2taxid")) %>% 
        filter(!endsWith(files, ".md5")) %>%
        filter(!files %in% c("prot.accession2taxid.FULL.gz", "prot.accession2taxid.gz"))

# Download files
download_files <- function(files_to_download, download_dir){
        for(i in 1:nrow(files_to_download)){
                file_url <- files_to_download[[i, "file_links"]]
                file_name <- file.path(download_dir, files_to_download[[i, "files"]])
                download.file(file_url, file_name, method = "auto")
        }
}

download_files(files_to_download, download_dir)

# Decompress files to the results folder
files_to_decompress <- list.files(download_dir)
files_to_decompress <- files_to_decompress[!grepl("\\.md5$", files_to_decompress)]

for(i in 1:length(files_to_decompress)){
        f <- files_to_decompress[[i]]
        gz_cmd <- paste0("gunzip -c ", file.path(download_dir, f), " > ", file.path(decompress_dir, tools::file_path_sans_ext(f)))
        system(gz_cmd)
}

stop()
# Concatenate decompressed files to a dataframe and save it as a feather file
comp_files <- list.files(decompress_dir)


#df_dat_out <- tibble()
for(i in 1:length(comp_files)){
        cat(comp_files[i], "\n")
        dat <- read_tsv(file.path(decompress_dir, comp_files[i]), show_col_types = FALSE) %>%
                dplyr::select(accession.version, taxid)
#       df_dat_out <- bind_rows(df_dat_out, dat)

        # Connect to SQLite database
        conn <- dbConnect(SQLite(), dbname = file.path("results", "accession-to-taxid.db"))

# Append the DataFrame to the database
# If the table doesn't exist, it will be created
        dbWriteTable(conn, "accession_to_taxid", dat, append = TRUE, row.names = FALSE)

# Close the connection
        dbDisconnect(conn)
}

