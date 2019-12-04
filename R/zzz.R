.onLoad = function(libname, pkgname) { # nocov start
  
  #Get user's working directory
  user_wd <- getwd()
  
  #Set temp dir as working rdirectory
  setwd(tempdir())
  
  #Create configuration file inside temp folder
  file.create("batchtools.conf.R")
  
  #Set default configuration parameters
  template_suffix <- "slurm"
  walltime_time <- "180L"
  memory_ammount <- "4700L"
  ntasks_ammount <- "1L"
  ncpus_ammount <- "1L"
  nodes_ammount <- "1L"
  
  #Parse the correct account name with the proper levelfs. This account id will be used in the slurm template.
  number_of_accounts <- system("sacctmgr -np  list account  WithAssoc Users=$USER | wc -l", intern = TRUE)
  number_of_accounts <- as.numeric(number_of_accounts)

  account_levelfs <- c()
  max_account_levelfs <- 0
  max_account_name <- c()

  for (i in 1:number_of_accounts)
  {
	
	parse_account_names <- system(paste("sacctmgr -np  list account  WithAssoc Users=$USER | head -n", i, "|tail -1 | cut -d'|' -f1"), intern = TRUE)

	parse_account_levelfs <- system(paste("sshare -np -u $USER -A ", parse_account_names, "| tail -n 1  | cut -d'|' -f7") , intern = TRUE)
	
	if (parse_account_levelfs == "inf") {
	parse_account_levelfs <- Inf
	}

	parse_account_levelfs <- as.numeric(parse_account_levelfs)



	if (parse_account_levelfs >= max_account_levelfs) {
	max_account_levelfs <- parse_account_levelfs
	max_account_name <- parse_account_names
	}
  }
  
  #' @importFrom stringr str_sub
  account_default_name_final <- stringr::str_sub(max_account_name, 1, -5)
  
  #Set welcome message when user loads the package	
  packageStartupMessage("\n\nWelcome to Batchtoolscc!\n\nYour default Slurm job account name is set to '", account_default_name_final, "' having the highest LevelFs '", max_account_levelfs , "'\n\n")

  max.concurrent.jobs_ammount <- "50L"
  batchtools.conf.R_filename <- "batchtools.conf.R"

  batchtools.conf.R_content <- paste0("cluster.functions = makeClusterFunctionsSlurm(template = '",template_suffix,"')\n\ndefault.resources <- list(walltime = ", walltime_time, ", memory = ",memory_ammount,", ntasks = ",ntasks_ammount,", ncpus = ",ncpus_ammount,", nodes = ",nodes_ammount,", account = '", account_default_name_final, "' )\n\nmax.concurrent.jobs <- ",max.concurrent.jobs_ammount,"")

  write(batchtools.conf.R_content, file = batchtools.conf.R_filename)

  #Create slurm template
  batchtools.slurm.tmpl_filename <- "batchtools.slurm.tmpl"

  file.create(batchtools.slurm.tmpl_filename)
  
  #Set slurm tempalate body
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
 
  #Create batchtools slurm template
  write(batchtools.slurm.tmpl_content, file = batchtools.slurm.tmpl_filename)
 
  #Return to user's login working directory
  setwd(user_wd)

  #Tell batchtools to search for the created config and template files in temp directory
  Sys.setenv(R_BATCHTOOLS_SEARCH_PATH = tempdir())
  #Every time the user logs out, these files will be deleted. Every time the user logs in they will be created again in the temp dir.
}
