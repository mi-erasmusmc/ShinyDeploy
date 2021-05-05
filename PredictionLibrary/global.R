# uncomment if running standalone
##runPlp <- readRDS(file.path("data","results.rds"))
##validatePlp <- readRDS(file.path("data","extValidation.rds"))
source("processing.R")

connectionPool <- pool::dbPool(drv = DatabaseConnector::DatabaseConnectorDriver(),
                               dbms = "postgresql",
                               server = paste(Sys.getenv("shinydbServer"),
                                              Sys.getenv("shinydbDatabase"),
                                              sep = "/"),
                               port = Sys.getenv("shinydbPort"),
                               user = Sys.getenv("covid19vaccinationplpdbUser"),
                               password = Sys.getenv("covid19vaccinationplpdbPw"))

onStop(function() {
  if (DBI::dbIsValid(connectionPool)) {
    writeLines("Closing connection pool")
    pool::poolClose(connectionPool)
  }
})

summaryTable <- DBI::dbGetQuery(conn = con, 
                                "SELECT results.result_id, results.model_id, researcher_id, result_type, database_acronym AS Dev, target_name AS T, outcome_name AS O,
   model_type AS model, TAR, AUC, population_size, outcome_count
   FROM results
    LEFT JOIN (SELECT cohort_id, cohort_name as target_name FROM cohorts) AS cohorts ON results.target_id = cohorts.cohort_id
    LEFT JOIN (SELECT cohort_id, cohort_name as outcome_name FROM cohorts) AS targets ON results.outcome_id = targets.cohort_id
    LEFT JOIN (SELECT database_id, database_acronym FROM databases) as dbs ON results.database_id = dbs.database_id 
    LEFT JOIN (SELECT model_id, model_type FROM model_settings) AS mset ON results.model_id = mset.model_id
    LEFT JOIN (SELECT result_id, AUC_auc AS AUC, population_size, outcome_count 
                      FROM evaluation_statistics) AS es ON results.result_id = es.result_id
   WHERE result_type = 'Development'")

