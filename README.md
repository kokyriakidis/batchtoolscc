# batchtoolscc
Extension Package for Batchtools. Fine-Tuned for Compute Canada HPC Systems

[![JOSS Publicatoin](http://joss.theoj.org/papers/10.21105/joss.00135/status.svg)](https://doi.org/10.21105/joss.00135)
[![CRAN Status Badge](http://www.r-pkg.org/badges/version/batchtools)](https://cran.r-project.org/package=batchtools)
[![Build Status](https://travis-ci.org/mllg/batchtools.svg?branch=master)](https://travis-ci.org/mllg/batchtools)
[![Build Status](https://ci.appveyor.com/api/projects/status/ypp14tiiqfhnv92k/branch/master?svg=true)](https://ci.appveyor.com/project/mllg/batchtools/branch/master)
[![Coverage Status](https://img.shields.io/coveralls/mllg/batchtools.svg)](https://coveralls.io/r/mllg/batchtools?branch=master)

As a successor of the packages [BatchJobs](https://github.com/tudo-r/BatchJobs) and [BatchExperiments](https://github.com/tudo-r/Batchexperiments), batchtools provides a parallel implementation of Map for high performance computing systems managed by schedulers like Slurm, Sun Grid Engine, OpenLava, TORQUE/OpenPBS, Load Sharing Facility (LSF) or Docker Swarm (see the setup section in the [vignette](https://mllg.github.io/batchtools/articles/batchtools.html)).

Main features:
* Convenience: All relevant batch system operations (submitting, listing, killing) are either handled internally or abstracted via simple R functions
* Portability: With a well-defined interface, the source is independent from the underlying batch system - prototype locally, deploy on any high performance cluster
* Reproducibility: Every computational part has an associated seed stored in a data base which ensures reproducibility even when the underlying batch system changes
* Abstraction: The code layers for algorithms, experiment definitions and execution are cleanly separated and allow to write readable and maintainable code to manage large scale computer experiments

**The most important feature of batchtoolscc package is that you do not have to configure it for your HPC system. Everything is automatically set and ready to run.**

# Installation
Install the stable release of devtools:
```{R}
install.packages("devtools")
```

Install batchtools_cc package, specifically fine-tuned to work with Compute Canada HPC systems:
```{R}
install_github("kokyriakidis/batchtoolscc")
```

# Preparing and submitting a job with batchtools
All relevant batch system operations (submitting, listing, killing) are either handled internally or abstracted via simple R functions. If ever you want to tweak these functions, here is how we use it.

Useful functions:

1) [loadRegistry](https://mllg.github.io/batchtools/reference/loadRegistry.html) creates a registry used to manipulate jobs for a particular analysis step. Use ```writable=TRUE``` if the registry already exists.

2) [batchMap](https://mllg.github.io/batchtools/reference/batchMap.html) adds jobs to a registry. You give it a function and a list of parameters. One job per parameter will be created to compute the output of the function using this specific parameter. ```more.args=``` to provide additional arguments (same for all jobs).

3) [submitJobs](https://mllg.github.io/batchtools/reference/submitJobs.html) submits the jobs to the cluster. This is where the walltime time, number of cores, etc can be specified. Moreover, if needed, a subset of the jobs can be sent to the cluster. Functions [findNotDone](https://mllg.github.io/batchtools/reference/findJobs.html) and [findErrors](https://mllg.github.io/batchtools/reference/findJobs.html) are particularly useful to find which jobs didn’t finish or were lost in the limbo of the cluster management process.

4) [getStatus](https://mllg.github.io/batchtools/reference/getStatus.html) outputs the status of the computations.

5) [loadResult](https://mllg.github.io/batchtools/reference/loadResult.html) retrieves the output of one specific job, while [reduceResultsList](https://mllg.github.io/batchtools/reference/reduceResultsList.html) retrieves output for all jobs into a list format.

6) [waitForJobs](https://mllg.github.io/batchtools/reference/waitForJobs.html) waits for all the jobs to finish.

# Testing with a simple job

It's a good idea to check that everything is configured properly before trying to run the pipeline. To test that sending jobs works you could try running the following commands:

```
module load nixpkgs/16.09 gcc/7.3.0  r/3.6.0

R

library(devtools)

install_github("kokyriakidis/batchtoolscc")

library(batchtoolscc)

## To start again from scratch, manually remove the 'test' folder.
reg <- makeRegistry('test', seed=123)
## reg = loadRegistry('test', writeable=TRUE) ## If the registry has already been created before

test.f <- function(ii){
	return(mean(rnorm(10,ii)))
}

batchMap(reg=reg, test.f, 1:2)
submitJobs(reg=reg, ids=findJobs(reg=reg), resources=list(walltime='10:00', cores=1))
waitForJobs(reg=reg, sleep=10)
getStatus(reg=reg)
reduceResultsList(reg=reg)
```

**These commands:**

1)  Load the package 
```
library(batchtoolscc)
``` 

2)  Create a registry called test
```
reg <- makeRegistry('test', seed=123)
```

3)  Define a function that will be run in the job
```
test.f <- function(ii){
        return(mean(rnorm(10,ii)))
}
```

4)  Setup two jobs with this function and inputs 1 and 2
```
batchMap(reg=reg, test.f, 1:2)
```

5)  Submit the jobs with a 10min walltime and 1 core per job
```
submitJobs(reg=reg, ids=findJobs(reg=reg), resources=list(walltime='10:00', cores=1))
```

6)  Wait for the jobs to finish
```
waitForJobs(reg=reg, sleep=10)
```

7)  Show a summary of the status
```
getStatus(reg=reg)
```

8)  List the results 
```
reduceResultsList(reg=reg)
```


# PopSV Use Case


## Installation


This install command requires devtools package which can be easily installed with :

```
install.packages("devtools")
```

Some Bioconductor packages are also necessary and not installed automatically. Running the following command should be sufficient :

```
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install()

BiocManager::install(c("BSgenome.Hsapiens.UCSC.hg19", "Rsamtools", "DNAcopy", "rtracklayer"))
```

**To use hg38 instead of hg19 install** ```BSgenome.Hsapiens.UCSC.hg38```.

Then, run the following to install the latest development version:

```
devtools::install_github("jmonlong/PopSV")
```
If you get an error, you can try the following instead:

```
devtools::install_git("git://github.com/jmonlong/PopSV.git")
```

**R 3.1 or higher is required.**


## Running the pipeline


### Automated run

Two wrapper functions around *batchtools* allows you to run PopSV without manually sending the jobs for each steps. 
These two functions (`autoGCcounts` and `autoNormTest`) are located in [`automatedPipeline-batchtools.R`](https://github.com/jmonlong/PopSV/tree/master/scripts/batchtools). 

**Place in the working directory:** 

- [`automatedPipeline-batchtools.R`](https://github.com/jmonlong/PopSV/tree/master/scripts/batchtools) which contains the pipeline functions.

The most important feature of batchtools_cc package is that you do not have to configure it for your HPC system. Everything is set and ready to run PopSV when you load ```batchtools_cc``` package using the following commands **in the working directory we are going to run the pipeline**.

**A full analysis can be run like this:**

```
##Load basic packages
module load nixpkgs/16.09 gcc/7.3.0  r/3.6.0

R

library(devtools)

install_github("kokyriakidis/batchtoolscc")

library(batchtoolscc)

library(PopSV)

## Load wrapper
source('automatedPipeline-batchtools.R')

genome = BSgenome.Hsapiens.UCSC.hg19::BSgenome.Hsapiens.UCSC.hg19
## or
## genome = BSgenome.Hsapiens.UCSC.hg38::BSgenome.Hsapiens.UCSC.hg38

##
## Preparation
## Run only once to create the files files.RData and bins.RData
##

bam.files = read.table("bams.tsv", as.is=TRUE, header=TRUE)
bin.size = 1e3

#### Init file names and construct bins
files.df = init.filenames(bam.files, code="example")
bins.df = fragment.genome(bin.size, genome=genome)
save(files.df, file="files.RData")
save(bins.df, file="bins.RData")
####


##
## Analysis
## Can be stopped and restarted. No need to rerun the preparation commands
##

## Bin and count reads in each bin
res.GCcounts = autoGCcounts("files.RData", "bins.RData", other.resources=list(account='rrg-bourqueg-ad'), genome=genome)

## QC (optional)
res.forQC = autoExtra("files.RData", "bins.RData", do=1, other.resources=list(account='rrg-bourqueg-ad')))
qc.samples.cluster(res.forQC) ## Run locally because it opens an interactive web browser application
##

## Normalize and call CNVs
res.df = autoNormTest("files.RData", "bins.RData", other.resources=list(account='rrg-bourqueg-ad')))
write.table(res.df, file='PopSV-CNVcalls.tsv', sep='\t', row.names=FALSE, quote=FALSE)

## Filter CNVs
res.filt.df = sv.summary.interactive(res.df) ## Run locally because it opens an interactive web browser application
write.table(res.filt.df, file='PopSV-CNVcalls-filtered.tsv', sep='\t', row.names=FALSE, quote=FALSE)



##
## Optional: Run additional samples using references from the previous analysis
##

## Option 1: in the same folder but using suffixes for the new batches
bam.files2 = read.table("bams2.tsv", as.is=TRUE, header=TRUE)
files.df = init.filenames(bam.files2, code="example2")
save(files.df, file="files2.RData")

res2.GCcounts = autoGCcorrect("files2.RData", "bins.RData", skip=1, file.suffix='batch2') # different suffix for batch2
res2.df = autoNormTest("files2.RData", "bins.RData", file.suffix.ref='', file.suffix='batch2') # and also specify suffix for reference analysis
write.table(res2.df, file='PopSV-CNVcalls-batch2.tsv', sep='\t', row.names=FALSE, quote=FALSE)

## Option 2: new batch in a separate folder
## Assuming that we work in a new "batch2" folder containing the "bams2.tsv' file
setwd('batch2') # update working directory
bam.files2 = read.table("bams2.tsv", as.is=TRUE, header=TRUE)
files.df = init.filenames(bam.files2, code="example2")
save(files.df, file="files2.RData")

res.GCcounts = autoGCcorrect("files2.RData", "../bins.RData", skip=1)
res.df = autoNormTest("files2.RData", "../bins.RData", ref.dir='..') # ref.dir specify the folder containing the reference analysis
write.table(res.df, file='PopSV-CNVcalls-batch2.tsv', sep='\t', row.names=FALSE, quote=FALSE)

```

In this example ```bams.tsv``` is a tab-delimited file with a column sample (with the sample names) and a column bam (with the path to each BAM file). **The BAM files must be sorted and indexed**.

The advantage of this wrapper is a easier management of the cluster and pipeline. 
However it's not so flexible: if a step need to be changed for some reason, you might have to change it within the `automatedPipeline-batchtools.R` script.

Still, a few parameters can be passed to the two functions for the user's convenience:

+ Use `lib.loc=` if you installed PopSV in a specific location. The value will be passed to `library(PopSV)`.
+ `redo=` can be used to force a step to be redone (i.e. previous jobs deleted and re-submitted). E.g. `redo=5` to redo step 5.
+ `other.resources=` to specify resources for the jobs to match the template (see HPC configuration section above). We use this to specify queues/accounts when the HPC requires it.
+ `resetError=TRUE` to reset jobs that had errors and rerun them. Better than a *redo* because the jobs that are done don't need to be rerun.
+ `rewrite=TRUE` will force the normalized bin counts and normalization stats to be rewritten.
+ `file.suffix=` to add a suffix to the temporary files. This is useful when the pipeline is run several times on the same folder, for example when splitting the samples in batches (e.g. presence of batch effects, male/female split for XY chrs).
+ `step.walltime=` the walltime for each step. See in the `automatedPipeline-batchtools.R` script for default values. 
+ `step.cores=` the number of cores for each step. See in the `automatedPipeline-batchtools.R` script for default values. 
+ `status=TRUE` will only print the status of the jobs for each steps and the log of jobs with errors.
+ `skip=` to skip some steps.


### Practical details


- `automatedPipeline-batchtools.R` script **should be in the working directory where batchtools package is loaded**. 
- Use different `file.suffix` if PopSV is run several times in the same folder (e.g. different bin size, sample batches).
- The paths and folder structure is saved in the `files.df` data.frame, originally created by  `init.filenames` function. 

### For more information please see the PopSV page:

```
http://jmonlong.github.io/PopSV/
```



# Why batchtools?
The development of [BatchJobs](https://github.com/tudo-r/BatchJobs/) and [BatchExperiments](https://github.com/tudo-r/Batchexperiments) is discontinued for the following reasons:

* Maintainability: The packages [BatchJobs](https://github.com/tudo-r/BatchJobs/) and [BatchExperiments](https://github.com/tudo-r/Batchexperiments) are tightly connected which makes maintenance difficult. Changes have to be synchronized and tested against the current CRAN versions for compatibility. Furthermore, BatchExperiments violates CRAN policies by calling internal functions of BatchJobs.
* Data base issues: Although we invested weeks to mitigate issues with locks of the SQLite data base or file system (staged queries, file system timeouts, ...), `BatchJobs` kept working unreliable on some systems with high latency under certain conditions. This made `BatchJobs` unusable for many users.

[BatchJobs](https://github.com/tudo-r/BatchJobs/) and [BatchExperiments](https://github.com/tudo-r/Batchexperiments) will remain on CRAN, but new features are unlikely to be ported back.
The [vignette](https://mllg.github.io/batchtools/articles/batchtools.html#migration) contains a section comparing the packages.


# Resources
* [NEWS](https://mllg.github.io/batchtools/news/)
* [Function reference](https://mllg.github.io/batchtools/reference)
* [Vignette](https://mllg.github.io/batchtools/articles/batchtools.html)
* [JOSS Paper](https://doi.org/10.21105/joss.00135): Short paper on batchtools. Please cite this if you use batchtools.
* [Paper on BatchJobs/BatchExperiments](http://www.jstatsoft.org/v64/i11): The described concept still holds for batchtools and most examples work analogously (see the [vignette](https://mllg.github.io/batchtools/articles/batchtools.html#migration) for differences between the packages).

# Citation
Please cite the [JOSS paper](https://doi.org/10.21105/joss.00135) using the following BibTeX entry:
```
@article{,
  doi = {10.21105/joss.00135},
  url = {https://doi.org/10.21105/joss.00135},
  year  = {2017},
  month = {feb},
  publisher = {The Open Journal},
  volume = {2},
  number = {10},
  author = {Michel Lang and Bernd Bischl and Dirk Surmann},
  title = {batchtools: Tools for R to work on batch systems},
  journal = {The Journal of Open Source Software}
}
```

# Related Software
* The [High Performance Computing Task View](https://cran.r-project.org/view=HighPerformanceComputing) lists the most relevant packages for scientific computing with R.
* [clustermq](https://cran.r-project.org/package=clustermq) is a similar approach which also supports multiple schedulers. Uses the ZeroMQ network protocol for communication, and shines if you have millions of fast jobs.
* [batch](https://cran.r-project.org/package=batch) assists in splitting and submitting jobs to LSF and MOSIX clusters.
* [flowr](https://cran.r-project.org/package=flowr) supports LSF, Slurm, TORQUE and Moab and provides a scatter-gather approach to define computational jobs.
* [future.batchtools](https://cran.r-project.org/package=future.batchtools) implements `batchtools` as backend for [future](https://cran.r-project.org/package=future.batchtools).
* [doFuture](https://cran.r-project.org/package=doFuture) together with [future.batchtools](https://cran.r-project.org/package=future.batchtools) connects `batchtools` to [foreach](https://cran.r-project.org/package=foreach).
* [drake](https://cran.r-project.org/package=drake) uses graphs to define computational jobs. `batchtools` is used as a backend via [future.batchtools](https://cran.r-project.org/package=future.batchtools).

# Contributing to batchtools
This R package is licensed under the [LGPL-3](https://www.gnu.org/licenses/lgpl-3.0.en.html).
If you encounter problems using this software (lack of documentation, misleading or wrong documentation, unexpected behaviour, bugs, ...) or just want to suggest features, please open an issue in the [issue tracker](https://github.com/mllg/batchtools/issues).
Pull requests are welcome and will be included at the discretion of the author.
If you have customized a template file for your (larger) computing site, please share it: fork the repository, place your template in `inst/templates` and send a pull request.
