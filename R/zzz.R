.onLoad = function(libname, pkgname) { # nocov start
  user_wd <- getwd()

  setwd(tempdir())

  file.create("batchtools.conf.R")

  template_suffix <- "slurm"
  walltime_time <- "180L"
  memory_ammount <- "4700L"
  ntasks_ammount <- "1L"
  ncpus_ammount <- "1L"
  nodes_ammount <- "1L"

  account_default_name_mixed <- system("sacctmgr -np  list account  WithAssoc Users=$USER | grep 'def' | head -n 1 | cut -d'|' -f1", intern = TRUE)

  #' @importFrom stringr str_sub
  account_default_name_final <- stringr::str_sub(account_default_name_mixed, 1, -5)
  
  packageStartupMessage("\n\nWelcome to Batchtoolscc. Your default Slurm job account name is set to \" ", account_default_name_final, " \"\n\n")

  max.concurrent.jobs_ammount <- "50L"
  batchtools.conf.R_filename <- "batchtools.conf.R"

  batchtools.conf.R_content <- paste0("cluster.functions = makeClusterFunctionsSlurm(template = '",template_suffix,"')\n\ndefault.resources <- list(walltime = ", walltime_time, ", memory = ",memory_ammount,", ntasks = ",ntasks_ammount,", ncpus = ",ncpus_ammount,", nodes = ",nodes_ammount,", account = '", account_default_name_final, "' )\n\nmax.concurrent.jobs <- ",max.concurrent.jobs_ammount,"")

  write(batchtools.conf.R_content, file = batchtools.conf.R_filename)

  batchtools.slurm.tmpl_filename <- "batchtools.slurm.tmpl"

  file.create(batchtools.slurm.tmpl_filename)

  batchtools.slurm.tmpl_content <- "#!/bin/bash\n\n \
#SBATCH --job-name=<%= job.name %>\n \
#SBATCH --output=<%= log.file %>\n \
#SBATCH --error=<%= log.file %>\n \
#SBATCH --time=<%= resources$walltime %>\n \
#SBATCH --ntasks=1\n \
#SBATCH --cpus-per-task=<%= resources$cores %>\n \
#SBATCH --mem-per-cpu=<%= resources$memory %>\n \
#SBATCH --account=<%= resources$account %>\n \
<%= if (!is.null(resources$partition)) sprintf(paste0(\"#SBATCH --partition='\", resources$partition, \"'\")) %>\n \
<%= if (array.jobs) sprintf(\"#SBATCH --array=1-%i\", nrow(jobs)) else \"\" %>\n\n \
## Initialize work environment like\n \
## source /etc/profile\n \
## module load nixpkgs/16.09 gcc/7.3.0  r/3.6.0 \
## Export value of DEBUGME environemnt var to slave\n \
export DEBUGME=<%= Sys.getenv(\"DEBUGME\") %>\n\n \
## Run R:\n \
## we merge R output with stdout from SLURM, which gets then logged via --output option\n \
Rscript -e 'batchtools::doJobCollection(\"<%= uri %>\")'\n"

  write(batchtools.slurm.tmpl_content, file = batchtools.slurm.tmpl_filename)

  setwd(user_wd)


  Sys.setenv(R_BATCHTOOLS_SEARCH_PATH = tempdir())

}
