# Query accession to taxid sqlite database 

library(DBI)
library(RSQLite)

conn <- dbConnect(RSQLite::SQLite(), file.path("results", "accession-to-taxid.db"))
tab <- dbListTables(conn) # list tables
dbListFields(conn, tab) # list column names in a given table

# Check the total size of the database
db_size <- dbGetQuery(conn, 'SELECT COUNT(*) FROM accession_to_taxid;')

# Check the number of unique accession numbers
uni_acc <- dbGetQuery(conn, 'SELECT COUNT(DISTINCT "accession.version") FROM accession_to_taxid;')

# Check the number of unique taxid
uni_tax <- dbGetQuery(conn, 'SELECT COUNT(DISTINCT "taxid") FROM accession_to_taxid;')

# Check the number of both accession number and taxid

dbGetQuery(conn, 'SELECT * FROM accession_to_taxid WHERE "accession.version" = "0508234A"')

